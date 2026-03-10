module Examples.ClickToLoad
    ( ClickToLoadAPI
    , clickToLoadServer
    , clickToLoadPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.IORef (IORef, readIORef, writeIORef)
import Data.Text (pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:<|>) (..), (:>))
import Servant.Datastar
    ( DatastarSSE
    , ElementPatchMode (..)
    , PatchElements (..)
    , ServerSentEventGenerator
    , StdMethod (..)
    , patchElements
    , sendPatchElements
    )

type ClickToLoadAPI =
    DatastarSSE 'GET
        :<|> "more" :> DatastarSSE 'GET

clickToLoadPage :: Html ()
clickToLoadPage = examplePage "Click To Load"
    $ div_
        ( [id_ "demo"]
            <> datastar
                ( onInit $
                    act $
                        get
                            "/examples/\
                            \click-to-load/data"
                )
        )
    $ do
        table_ $ do
            thead_ $
                tr_ $ do
                    th_ "Name"
                    th_ "Email"
                    th_ "ID"
            tbody_ [id_ "rows"] mempty
        div_ [id_ "load-btn"] $
            button_
                ( [class_ "contrast"]
                    <> datastar
                        ( on "click" [] $
                            act $
                                get
                                    "/examples/\
                                    \click-to-load/\
                                    \data/more"
                        )
                )
                "Load More"

clickToLoadServer
    :: IORef Int
    -> Handler (ServerSentEventGenerator -> IO ())
        :<|> Handler
                (ServerSentEventGenerator -> IO ())
clickToLoadServer ref =
    initialLoad ref :<|> loadMore ref

pageSize :: Int
pageSize = 10

initialLoad
    :: IORef Int
    -> Handler (ServerSentEventGenerator -> IO ())
initialLoad ref = liftIO $ do
    writeIORef ref pageSize
    pure $ \gen ->
        sendPatchElements gen $
            (patchElements $ render $ generateRows 0 pageSize)
                { peSelector = Just "#rows"
                , peMode = Append
                }

loadMore
    :: IORef Int
    -> Handler (ServerSentEventGenerator -> IO ())
loadMore ref = liftIO $ do
    offset <- readIORef ref
    writeIORef ref (offset + pageSize)
    pure $ \gen ->
        sendPatchElements gen $
            ( patchElements $
                render $
                    generateRows offset pageSize
            )
                { peSelector = Just "#rows"
                , peMode = Append
                }

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
