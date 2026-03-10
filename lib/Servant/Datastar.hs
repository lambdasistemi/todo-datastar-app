module Servant.Datastar
    ( -- * Combinators
      DatastarPatch
    , DatastarSSE
    , DatastarSignals

      -- * Re-export StdMethod for DataKinds
    , StdMethod (..)

      -- * Re-exports from datastar-hs
    , ServerSentEventGenerator
    , PatchElements (..)
    , PatchSignals (..)
    , ElementPatchMode (..)
    , patchElements
    , patchSignals
    , sendPatchElements
    , sendPatchSignals
    , sendExecuteScript
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.Text (Text)
import Hypermedia.Datastar
    ( ElementPatchMode (..)
    , PatchElements (..)
    , PatchSignals (..)
    , ServerSentEventGenerator
    , nullLogger
    , patchElements
    , patchSignals
    , readSignals
    , sendExecuteScript
    , sendPatchElements
    , sendPatchSignals
    , sseResponse
    )
import Network.HTTP.Types (StdMethod (..))
import Servant
    ( HasServer (..)
    , Proxy (..)
    , ServerError (..)
    )
import Servant.API (ReflectMethod (..), (:>))
import Servant.Server.Internal
    ( RouteResult (..)
    , addMethodCheck
    , leafRouter
    , methodCheck
    , runAction
    )
import Servant.Server.Internal.Delayed (addBodyCheck)
import Servant.Server.Internal.DelayedIO
    ( delayedFailFatal
    , withRequest
    )

{- | Simple datastar SSE endpoint.

Handler returns 'Text' (HTML fragment), which
gets wrapped in a single @patchElements@ SSE
event with default outer morph mode.
-}
data DatastarPatch (method :: k)

instance
    (ReflectMethod method)
    => HasServer (DatastarPatch method) context
    where
    type ServerT (DatastarPatch method) m = m Text

    hoistServerWithContext _ _ nt = nt

    route Proxy _ctx action =
        leafRouter $ \env request respond ->
            let method' =
                    reflectMethod (Proxy :: Proxy method)
                action' =
                    addMethodCheck
                        action
                        (methodCheck method' request)
            in  runAction
                    action'
                    env
                    request
                    respond
                    $ \txt ->
                        Route $
                            sseResponse nullLogger $ \gen ->
                                sendPatchElements gen $
                                    patchElements txt

{- | Full SSE endpoint combinator.

Handler receives 'ServerSentEventGenerator' and
can send multiple events, use different merge
modes, patch signals, etc. The connection stays
open until the handler returns.
-}
data DatastarSSE (method :: k)

instance
    (ReflectMethod method)
    => HasServer (DatastarSSE method) context
    where
    type
        ServerT (DatastarSSE method) m =
            m (ServerSentEventGenerator -> IO ())

    hoistServerWithContext _ _ nt = nt

    route Proxy _ctx action =
        leafRouter $ \env request respond ->
            let method' =
                    reflectMethod (Proxy :: Proxy method)
                action' =
                    addMethodCheck
                        action
                        (methodCheck method' request)
            in  runAction
                    action'
                    env
                    request
                    respond
                    $ \handler ->
                        Route $
                            sseResponse nullLogger handler

{- | Extract datastar signals from request.

Parses signals via @readSignals@ from
datastar-hs (handles both body and query
params).
-}
data DatastarSignals a

instance
    (FromJSON a, HasServer api context)
    => HasServer (DatastarSignals a :> api) context
    where
    type
        ServerT (DatastarSignals a :> api) m =
            a -> ServerT api m

    hoistServerWithContext _ ctx nt s =
        hoistServerWithContext
            (Proxy :: Proxy api)
            ctx
            nt
            . s

    route Proxy ctx action =
        route (Proxy :: Proxy api) ctx $
            addBodyCheck
                action
                (pure ())
                ( \() -> withRequest $ \req -> do
                    result <- liftIO (readSignals req)
                    case result of
                        Left _err ->
                            delayedFailFatal
                                ServerError
                                    { errHTTPCode = 400
                                    , errReasonPhrase =
                                        "Bad Request"
                                    , errBody =
                                        "Bad signals"
                                    , errHeaders = []
                                    }
                        Right signals -> pure signals
                )
