module Examples.ProgressBar
    ( ProgressBarAPI
    , progressBarServer
    , progressBarPage
    ) where

import Control.Concurrent (threadDelay)
import Control.Monad (when)
import Control.Monad.IO.Class (liftIO)
import Data.IORef (IORef, readIORef, writeIORef)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:<|>) (..), (:>))
import Servant.Datastar
    ( DatastarSSE
    , ServerSentEventGenerator
    , StdMethod (..)
    , patchElements
    , sendPatchElements
    )

type ProgressBarAPI =
    "start" :> DatastarSSE 'GET
        :<|> "reset" :> DatastarSSE 'GET

progressBarPage :: Html ()
progressBarPage = examplePage "Progress Bar" $
    div_ [id_ "demo"] $ do
        progressHtml 0
        div_ [role_ "group"] $ do
            button_
                ( datastar $
                    on "click" [] $
                        act $
                            get (base <> "/start")
                )
                "Start"
            button_
                ( datastar $
                    on "click" [] $
                        act $
                            get (base <> "/reset")
                )
                "Reset"

progressBarServer
    :: IORef Int
    -> Handler
        (ServerSentEventGenerator -> IO ())
        :<|> Handler
                (ServerSentEventGenerator -> IO ())
progressBarServer ref =
    startProgress ref :<|> resetProgress ref

base :: Text
base = "/examples/progress-bar/data"

startProgress
    :: IORef Int
    -> Handler
        (ServerSentEventGenerator -> IO ())
startProgress ref = liftIO $ do
    pure $ \gen -> do
        let loop = do
                val <- readIORef ref
                when (val < 100) $ do
                    let next = min 100 (val + 10)
                    writeIORef ref next
                    sendPatchElements gen $
                        patchElements $
                            render $
                                progressHtml next
                    threadDelay 500000
                    loop
        loop

resetProgress
    :: IORef Int
    -> Handler
        (ServerSentEventGenerator -> IO ())
resetProgress ref = liftIO $ do
    writeIORef ref 0
    pure $ \gen ->
        sendPatchElements gen $
            patchElements $
                render $
                    progressHtml 0

progressHtml :: Int -> Html ()
progressHtml pct =
    div_ [id_ "demo"] $ do
        progress_
            [ value_ (showT pct)
            , max_ "100"
            ]
            mempty
        p_ $ toHtml $ showT pct <> "%"
        div_ [role_ "group"] $ do
            button_
                ( datastar $
                    on "click" [] $
                        act $
                            get (base <> "/start")
                )
                "Start"
            button_
                ( datastar $
                    on "click" [] $
                        act $
                            get (base <> "/reset")
                )
                "Reset"

showT :: Int -> Text
showT = pack . show
