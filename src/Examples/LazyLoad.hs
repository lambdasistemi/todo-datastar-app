module Examples.LazyLoad
    ( LazyLoadAPI
    , lazyLoadServer
    , lazyLoadPage
    ) where

import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler)
import Servant.Datastar (DatastarPatch, StdMethod (..))

type LazyLoadAPI = DatastarPatch 'GET

lazyLoadPage :: Html ()
lazyLoadPage =
    examplePage "Lazy Load"
        $ div_
            ( [id_ "demo"]
                <> datastar
                    ( onInit $
                        act $
                            get "/examples/lazy-load/data"
                    )
            )
        $ p_ "Loading..."

lazyLoadServer :: Handler Text
lazyLoadServer = liftIO $ do
    threadDelay 1000000
    pure $
        render $
            div_ [id_ "demo"] $ do
                h2_ "Loaded!"
                p_
                    "This content was loaded lazily \
                    \from the server after a 1 second \
                    \delay."
