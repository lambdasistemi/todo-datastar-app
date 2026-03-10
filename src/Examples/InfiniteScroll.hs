module Examples.InfiniteScroll
    ( InfiniteScrollAPI
    , infiniteScrollServer
    , infiniteScrollPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.IORef (IORef, readIORef, writeIORef)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler)
import Servant.Datastar
    ( DatastarSSE
    , ElementPatchMode (..)
    , PatchElements (..)
    , ServerSentEventGenerator
    , StdMethod (..)
    , patchElements
    , sendPatchElements
    )

type InfiniteScrollAPI =
    DatastarSSE 'GET

infiniteScrollPage :: Html ()
infiniteScrollPage =
    examplePage "Infinite Scroll" $
        div_ [id_ "demo"] $ do
            table_ $ do
                thead_ $
                    tr_ $ do
                        th_ "Name"
                        th_ "Email"
                        th_ "ID"
                tbody_ [id_ "rows"] mempty
            div_
                ( [id_ "sentinel"]
                    <> datastar
                        ( onIntersect [] $
                            act $
                                get base
                        )
                )
                "Loading..."

infiniteScrollServer
    :: IORef Int
    -> Handler
        (ServerSentEventGenerator -> IO ())
infiniteScrollServer ref = liftIO $ do
    offset <- readIORef ref
    let newOffset = offset + pageSize
    writeIORef ref newOffset
    pure $ \gen -> do
        sendPatchElements gen $
            (patchElements $ render $ generateRows offset pageSize)
                { peSelector = Just "#rows"
                , peMode = Append
                }
        sendPatchElements gen $
            (patchElements $ render sentinelHtml)
                { peSelector = Just "#sentinel"
                }
  where
    sentinelHtml :: Html ()
    sentinelHtml =
        div_
            ( [id_ "sentinel"]
                <> datastar
                    ( onIntersect [] $
                        act $
                            get base
                    )
            )
            "Loading..."

base :: Text
base = "/examples/infinite-scroll/data"

pageSize :: Int
pageSize = 20

generateRows :: Int -> Int -> Html ()
generateRows offset count =
    mapM_ agentRow [offset .. offset + count - 1]

agentRow :: Int -> Html ()
agentRow n =
    tr_ $ do
        td_ $ toHtml $ "Agent Smith " <> show' n
        td_ $
            toHtml $
                "agent" <> show' n <> "@example.com"
        td_ $ toHtml $ show' n
  where
    show' = pack . show
