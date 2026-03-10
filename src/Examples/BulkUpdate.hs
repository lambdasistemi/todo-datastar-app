module Examples.BulkUpdate
    ( BulkUpdateAPI
    , bulkUpdateServer
    , bulkUpdatePage
    , defaultItems
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.IORef
    ( IORef
    , readIORef
    , writeIORef
    )
import Data.List.Extra (collect, item, items)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:<|>) (..), (:>))
import Servant.Datastar (DatastarPatch, StdMethod (..))

data Status = Active | Inactive
    deriving (Show, Eq)

data Item = Item
    { itemName :: Text
    , itemStatus :: Status
    }

defaultItems :: [Item]
defaultItems =
    [ Item "Item 1" Active
    , Item "Item 2" Active
    , Item "Item 3" Inactive
    , Item "Item 4" Active
    , Item "Item 5" Inactive
    ]

type BulkUpdateAPI =
    DatastarPatch 'GET
        :<|> "activate"
            :> DatastarPatch 'PUT
        :<|> "deactivate"
            :> DatastarPatch 'PUT

bulkUpdatePage :: Html ()
bulkUpdatePage =
    examplePage "Bulk Update" $
        div_
            ( [id_ "demo"]
                <> datastar
                    ( onInit $
                        act $
                            get base
                    )
            )
            mempty

bulkUpdateServer
    :: IORef [Item]
    -> Handler Text
        :<|> Handler Text
        :<|> Handler Text
bulkUpdateServer ref =
    getTable ref
        :<|> activateAll ref
        :<|> deactivateAll ref

base :: Text
base = "/examples/bulk-update/data"

getTable :: IORef [Item] -> Handler Text
getTable ref =
    liftIO $ render . tableHtml <$> readIORef ref

activateAll :: IORef [Item] -> Handler Text
activateAll ref = liftIO $ do
    items' <- readIORef ref
    let updated =
            fmap (\i -> i{itemStatus = Active}) items'
    writeIORef ref updated
    pure $ render $ tableHtml updated

deactivateAll :: IORef [Item] -> Handler Text
deactivateAll ref = liftIO $ do
    items' <- readIORef ref
    let updated =
            fmap (\i -> i{itemStatus = Inactive}) items'
    writeIORef ref updated
    pure $ render $ tableHtml updated

tableHtml :: [Item] -> Html ()
tableHtml items' =
    div_ [id_ "demo"] $ do
        table_ $ do
            thead_ $
                tr_ $ do
                    th_ "Name"
                    th_ "Status"
            tbody_ $
                mapM_ rowHtml items'
        div_ [role_ "group"] $ do
            button_
                ( collect $ do
                    item $ class_ "contrast"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    put (base <> "/activate")
                )
                "Activate All"
            button_
                ( collect $ do
                    item $ class_ "secondary"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    put
                                        ( base
                                            <> "/deactivate"
                                        )
                )
                "Deactivate All"

rowHtml :: Item -> Html ()
rowHtml Item{itemName, itemStatus} =
    tr_ $ do
        td_ $ toHtml itemName
        td_ $
            toHtml $
                pack $
                    show itemStatus
