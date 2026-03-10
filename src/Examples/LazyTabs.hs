module Examples.LazyTabs
    ( LazyTabsAPI
    , lazyTabsServer
    , lazyTabsPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Base (makeAttribute)
import Lucid.Datastar
import Servant (Capture, Handler, (:>))
import Servant.Datastar (DatastarPatch, StdMethod (..))

tabCount :: Int
tabCount = 5

type LazyTabsAPI =
    Capture "tab" Int :> DatastarPatch 'GET

lazyTabsPage :: Html ()
lazyTabsPage =
    examplePage "Lazy Tabs" $
        tabsHtml 0

lazyTabsServer :: Int -> Handler Text
lazyTabsServer = liftIO . pure . render . tabsHtml

tabsHtml :: Int -> Html ()
tabsHtml active =
    div_ [id_ "demo"] $ do
        div_ [role_ "tablist"] $
            mapM_ (tabButton active) [0 .. tabCount - 1]
        div_ [role_ "tabpanel"] $
            tabContent active

tabButton :: Int -> Int -> Html ()
tabButton active idx =
    button_
        ( [ role_ "tab"
          , makeAttribute
                "aria-selected"
                ( if idx == active
                    then "true"
                    else "false"
                )
          ]
            <> datastar
                ( on "click" [] $
                    act $
                        get $
                            "/examples/lazy-tabs/data/"
                                <> pack (show idx)
                )
        )
        $ toHtml ("Tab " <> pack (show idx))

tabContent :: Int -> Html ()
tabContent n =
    p_ $
        toHtml $
            "This is the content for tab "
                <> pack (show n)
                <> ". It was loaded from the server."
