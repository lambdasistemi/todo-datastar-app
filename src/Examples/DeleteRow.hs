module Examples.DeleteRow
    ( DeleteRowAPI
    , deleteRowServer
    , deleteRowPage
    , defaultContacts
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.IORef (IORef, modifyIORef', readIORef)
import Data.List.Extra (collect, item, items)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant
    ( Capture
    , Handler
    , (:<|>) (..)
    , (:>)
    )
import Servant.Datastar (DatastarPatch, StdMethod (..))

data Contact = Contact
    { contactId :: Int
    , contactName :: Text
    , contactEmail :: Text
    }

defaultContacts :: [Contact]
defaultContacts =
    [ Contact 0 "Joe Smith" "joe@smith.org"
    , Contact 1 "Angie MacDowell" "angie@macdowell.org"
    , Contact 2 "Fuqua Tarkenton" "fuqua@tarkenton.org"
    , Contact 3 "Kim Yee" "kim@yee.org"
    ]

type DeleteRowAPI =
    DatastarPatch 'GET
        :<|> Capture "id" Int
            :> DatastarPatch 'DELETE

deleteRowPage :: Html ()
deleteRowPage =
    examplePage "Delete Row" $
        div_
            ( [id_ "demo"]
                <> datastar
                    ( onInit $
                        act $
                            get "/examples/delete-row/data"
                    )
            )
            mempty

deleteRowServer
    :: IORef [Contact]
    -> Handler Text :<|> (Int -> Handler Text)
deleteRowServer ref =
    getTable ref :<|> deleteContact ref

getTable :: IORef [Contact] -> Handler Text
getTable ref =
    liftIO $ render . tableHtml <$> readIORef ref

deleteContact
    :: IORef [Contact] -> Int -> Handler Text
deleteContact ref cid = liftIO $ do
    modifyIORef' ref $
        filter (\c -> contactId c /= cid)
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
                mapM_ rowHtml contacts

rowHtml :: Contact -> Html ()
rowHtml Contact{contactId, contactName, contactEmail} =
    tr_ $ do
        td_ $ toHtml contactName
        td_ $ toHtml contactEmail
        td_ $
            button_
                ( collect $ do
                    item $ class_ "secondary"
                    items $
                        datastar $
                            on "click" [] $
                                raw
                                    "confirm(\
                                    \'Are you sure?')"
                                    &&. act
                                        ( delete $
                                            "/examples/\
                                            \delete-row/\
                                            \data/"
                                                <> pack
                                                    ( show
                                                        contactId
                                                    )
                                        )
                )
                "Delete"
