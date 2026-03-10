module Examples.EditRow
    ( EditRowAPI
    , editRowServer
    , editRowPage
    , defaultContacts
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.IORef (IORef, modifyIORef', readIORef)
import Data.List.Extra (collect, item, items)
import Data.Text (Text, pack)
import GHC.Generics (Generic)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant
    ( Capture
    , Handler
    , (:<|>) (..)
    , (:>)
    )
import Servant.Datastar
    ( DatastarPatch
    , DatastarSignals
    , StdMethod (..)
    )

data Contact = Contact
    { contactId :: Int
    , contactName :: Text
    , contactEmail :: Text
    }

data EditSignals = EditSignals
    { name :: Text
    , email :: Text
    }
    deriving (Generic)

instance FromJSON EditSignals

defaultContacts :: [Contact]
defaultContacts =
    [ Contact 0 "Joe Smith" "joe@smith.org"
    , Contact 1 "Angie MacDowell" "angie@macdowell.org"
    , Contact 2 "Fuqua Tarkenton" "fuqua@tarkenton.org"
    , Contact 3 "Kim Yee" "kim@yee.org"
    ]

type EditRowAPI =
    DatastarPatch 'GET
        :<|> Capture "id" Int
            :> "edit"
            :> DatastarPatch 'GET
        :<|> Capture "id" Int
            :> DatastarSignals EditSignals
            :> DatastarPatch 'PATCH

editRowPage :: Html ()
editRowPage =
    examplePage "Edit Row" $
        div_
            ( [id_ "demo"]
                <> datastar
                    ( onInit $
                        act $
                            get "/examples/edit-row/data"
                    )
            )
            mempty

editRowServer
    :: IORef [Contact]
    -> Handler Text
        :<|> (Int -> Handler Text)
        :<|> (Int -> EditSignals -> Handler Text)
editRowServer ref =
    getTable ref
        :<|> getEdit ref
        :<|> patchSave ref

base :: Text
base = "/examples/edit-row/data"

getTable :: IORef [Contact] -> Handler Text
getTable ref =
    liftIO $ render . tableHtml <$> readIORef ref

getEdit :: IORef [Contact] -> Int -> Handler Text
getEdit ref cid =
    liftIO $ do
        cs <- readIORef ref
        pure $ case filter (\c -> contactId c == cid) cs of
            (c : _) -> render $ editRowHtml c
            [] -> render $ p_ "Not found"

patchSave
    :: IORef [Contact]
    -> Int
    -> EditSignals
    -> Handler Text
patchSave ref cid EditSignals{name, email} = liftIO $ do
    modifyIORef' ref $
        fmap
            ( \c ->
                if contactId c == cid
                    then
                        c
                            { contactName = name
                            , contactEmail = email
                            }
                    else c
            )
    render . tableHtml <$> readIORef ref

tableHtml :: [Contact] -> Html ()
tableHtml contacts =
    div_ [id_ "demo"] $
        table_ $ do
            thead_ $
                tr_ $ do
                    th_ "Name"
                    th_ "Email"
                    th_ "Actions"
            tbody_ $
                mapM_ viewRowHtml contacts

viewRowHtml :: Contact -> Html ()
viewRowHtml Contact{contactId, contactName, contactEmail} =
    tr_ $ do
        td_ $ toHtml contactName
        td_ $ toHtml contactEmail
        td_ $
            button_
                ( collect $ do
                    item $ class_ "contrast"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    get $
                                        base
                                            <> "/"
                                            <> showT contactId
                                            <> "/edit"
                )
                "Edit"

editRowHtml :: Contact -> Html ()
editRowHtml Contact{contactId, contactName, contactEmail} =
    div_ [id_ "demo"]
        $ form_
            ( datastar $ do
                signal "name" $
                    "'" <> contactName <> "'"
                signal "email" $
                    "'" <> contactEmail <> "'"
            )
        $ do
            label_ $ do
                "Name"
                input_
                    ( collect $ do
                        item $ type_ "text"
                        item $ value_ contactName
                        items $ datastar $ bind "name"
                    )
            label_ $ do
                "Email"
                input_
                    ( collect $ do
                        item $ type_ "email"
                        item $ value_ contactEmail
                        items $ datastar $ bind "email"
                    )
            div_ [role_ "group"] $ do
                button_
                    ( collect $ do
                        item $ class_ "contrast"
                        items $
                            datastar $
                                on "click" [] $
                                    act $
                                        patch $
                                            base
                                                <> "/"
                                                <> showT
                                                    contactId
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

showT :: Int -> Text
showT = pack . show
