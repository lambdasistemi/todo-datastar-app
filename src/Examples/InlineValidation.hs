module Examples.InlineValidation
    ( InlineValidationAPI
    , inlineValidationServer
    , inlineValidationPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.Text (Text, isInfixOf, length, null)
import GHC.Generics (Generic)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:>))
import Servant.Datastar
    ( DatastarPatch
    , DatastarSignals
    , StdMethod (..)
    )
import Prelude hiding (length, null)

newtype EmailSignals = EmailSignals
    { email :: Text
    }
    deriving (Generic)
    deriving anyclass (FromJSON)

type InlineValidationAPI =
    "validate"
        :> DatastarSignals EmailSignals
        :> DatastarPatch 'POST

inlineValidationPage :: Html ()
inlineValidationPage =
    examplePage "Inline Validation" $
        div_ [id_ "demo"] $ do
            label_ $ do
                "Email"
                input_
                    ( [ type_ "email"
                      , placeholder_
                            "Enter email..."
                      ]
                        <> datastar
                            ( do
                                signal "email" "''"
                                bind "email"
                                on
                                    "keydown"
                                    [Debounce "500ms"]
                                    $ act
                                    $ post
                                        ( base
                                            <> "/validate"
                                        )
                            )
                    )
            div_ [id_ "validation"] mempty

inlineValidationServer
    :: EmailSignals -> Handler Text
inlineValidationServer (EmailSignals email') =
    liftIO $ pure $ render $ validationHtml email'

base :: Text
base = "/examples/inline-validation/data"

validationHtml :: Text -> Html ()
validationHtml email'
    | null email' =
        div_ [id_ "validation"] mempty
    | not ("@" `isInfixOf` email') =
        div_ [id_ "validation"] $
            small_
                [style_ "color: red"]
                "Must contain @"
    | length email' < 5 =
        div_ [id_ "validation"] $
            small_
                [style_ "color: red"]
                "Too short"
    | otherwise =
        div_ [id_ "validation"] $
            small_
                [style_ "color: green"]
                "Looks good!"
