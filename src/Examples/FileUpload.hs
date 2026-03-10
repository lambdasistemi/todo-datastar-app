module Examples.FileUpload
    ( FileUploadAPI
    , fileUploadServer
    , fileUploadPage
    ) where

import Data.Text (Text)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:>))
import Servant.Datastar (DatastarPatch, StdMethod (..))

type FileUploadAPI =
    "upload" :> DatastarPatch 'POST

fileUploadPage :: Html ()
fileUploadPage = examplePage "File Upload" $
    div_ [id_ "demo"] $ do
        p_
            "File upload requires browser file \
            \reading APIs. This example shows the \
            \datastar attribute setup."
        input_
            ( [ type_ "file"
              , id_ "file-input"
              ]
                <> datastar
                    ( do
                        signal "fileData" "''"
                        onChange [] $
                            raw
                                "(() => { \
                                \const f = \
                                \document\
                                \.getElementById\
                                \('file-input')\
                                \.files[0]; \
                                \if(f) { \
                                \const r = new \
                                \FileReader(); \
                                \r.onload = (e) \
                                \=> { $fileData \
                                \= e.target\
                                \.result }; \
                                \r.readAsDataURL\
                                \(f) } })()"
                    )
            )
        div_ [id_ "preview"] mempty
        button_
            ( datastar $
                on "click" [] $
                    act $
                        post (base <> "/upload")
            )
            "Upload"

fileUploadServer :: Handler Text
fileUploadServer =
    pure $
        render $
            div_ [id_ "demo"] $
                p_ "File uploaded successfully!"

base :: Text
base = "/examples/file-upload/data"
