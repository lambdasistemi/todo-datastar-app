module Layout
    ( HTML
    , page
    , examplePage
    , render
    ) where

import Data.ByteString.Lazy qualified as LBS
import Data.Text (Text)
import Data.Text.Lazy qualified as LT
import Lucid
import Network.HTTP.Media ((//))
import Servant.API.ContentTypes (Accept (..), MimeRender (..))

-- | HTML content type for serving pages
data HTML

instance Accept HTML where
    contentType _ = "text" // "html"

instance MimeRender HTML LBS.ByteString where
    mimeRender _ = id

-- | Shared page shell with pico.css and datastar
page :: Text -> Html () -> Html ()
page title' body' = doctypehtml_ $ do
    head_ $ do
        meta_ [charset_ "utf-8"]
        meta_
            [ name_ "viewport"
            , content_
                "width=device-width, initial-scale=1"
            ]
        title_ $ toHtml title'
        link_
            [ rel_ "stylesheet"
            , href_
                "https://cdn.jsdelivr.net/npm/\
                \@picocss/pico@2/css/pico.min.css"
            ]
        script_
            [ type_ "module"
            , src_
                "https://cdn.jsdelivr.net/gh/\
                \starfederation/datastar@1.0.0-RC.8/\
                \bundles/datastar.js"
            ]
            ("" :: Text)
    body_ $
        main_ [class_ "container"] body'

-- | Example page with title and back link
examplePage :: Text -> Html () -> Html ()
examplePage title' body' = page title' $ do
    nav_ $ a_ [href_ "/"] "← Examples"
    h1_ $ toHtml title'
    body'

-- | Render Html to strict Text
render :: Html () -> Text
render = LT.toStrict . renderText
