module Examples.ClickToEdit
    ( ClickToEditAPI
    , clickToEditServer
    , clickToEditPage
    , defaultContact
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.IORef (IORef, readIORef, writeIORef)
import Data.List.Extra (collect, item, items)
import Data.Text (Text)
import GHC.Generics (Generic)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:<|>) (..), (:>))
import Servant.Datastar
    ( DatastarPatch
    , DatastarSignals
    , StdMethod (..)
    )

data Contact = Contact
    { firstName :: Text
    , lastName :: Text
    , email :: Text
    }
    deriving (Generic)
    deriving anyclass (FromJSON)

defaultContact :: Contact
defaultContact =
    Contact "John" "Doe" "john@example.com"

type ClickToEditAPI =
    DatastarPatch 'GET
        :<|> "edit" :> DatastarPatch 'GET
        :<|> DatastarSignals Contact
            :> DatastarPatch 'PUT
        :<|> "reset" :> DatastarPatch 'PATCH

clickToEditPage :: Html ()
clickToEditPage =
    examplePage "Click To Edit" $
        div_
            ( [id_ "demo"]
                <> datastar
                    (onInit $ act $ get base)
            )
            mempty

clickToEditServer
    :: IORef Contact
    -> Handler Text
        :<|> Handler Text
        :<|> (Contact -> Handler Text)
        :<|> Handler Text
clickToEditServer ref =
    getView ref
        :<|> getEdit ref
        :<|> putSave ref
        :<|> patchReset ref

base :: Text
base = "/examples/click-to-edit/data"

getView :: IORef Contact -> Handler Text
getView ref =
    liftIO $ render . viewHtml <$> readIORef ref

getEdit :: IORef Contact -> Handler Text
getEdit ref =
    liftIO $ render . editHtml <$> readIORef ref

putSave :: IORef Contact -> Contact -> Handler Text
putSave ref contact = liftIO $ do
    writeIORef ref contact
    pure $ render $ viewHtml contact

patchReset :: IORef Contact -> Handler Text
patchReset ref = liftIO $ do
    writeIORef ref defaultContact
    pure $ render $ viewHtml defaultContact

viewHtml :: Contact -> Html ()
viewHtml Contact{firstName, lastName, email} =
    div_ [id_ "demo"] $ do
        p_ $ do
            strong_ "First Name: "
            toHtml firstName
        p_ $ do
            strong_ "Last Name: "
            toHtml lastName
        p_ $ do
            strong_ "Email: "
            toHtml email
        div_ [role_ "group"] $ do
            button_
                ( collect $ do
                    item $ class_ "contrast"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    get (base <> "/edit")
                )
                "Edit"
            button_
                ( collect $ do
                    item $ class_ "secondary"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    patch
                                        (base <> "/reset")
                )
                "Reset"

editHtml :: Contact -> Html ()
editHtml Contact{firstName, lastName, email} =
    div_
        ( [id_ "demo"]
            <> datastar
                ( do
                    signal
                        "first-name"
                        ("'" <> firstName <> "'")
                    signal
                        "last-name"
                        ("'" <> lastName <> "'")
                    signal
                        "email"
                        ("'" <> email <> "'")
                )
        )
        $ do
            label_ $ do
                "First Name"
                input_
                    ( collect $ do
                        item $ type_ "text"
                        item $ value_ firstName
                        items $
                            datastar $
                                bind "first-name"
                    )
            label_ $ do
                "Last Name"
                input_
                    ( collect $ do
                        item $ type_ "text"
                        item $ value_ lastName
                        items $
                            datastar $
                                bind "last-name"
                    )
            label_ $ do
                "Email"
                input_
                    ( collect $ do
                        item $ type_ "email"
                        item $ value_ email
                        items $
                            datastar $
                                bind "email"
                    )
            div_ [role_ "group"] $ do
                button_
                    ( collect $ do
                        item $ class_ "contrast"
                        items $
                            datastar $
                                on "click" [] $
                                    act $
                                        put base
                    )
                    "Save"
                button_
                    ( collect $ do
                        item $ class_ "secondary"
                        items $
                            datastar $
                                on "click" [] $
                                    act $
                                        get base
                    )
                    "Cancel"
