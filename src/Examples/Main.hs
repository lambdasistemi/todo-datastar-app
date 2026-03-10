module Main (main) where

import Data.ByteString.Lazy qualified as LBS
import Data.IORef (newIORef)
import Lucid (Html, renderBS)
import Network.Wai.Handler.Warp qualified as Warp
import Servant
    ( Get
    , Handler
    , Proxy (..)
    , serve
    , (:<|>) (..)
    , (:>)
    )
import System.Environment (lookupEnv)

import Examples.ActiveSearch
    ( ActiveSearchAPI
    , activeSearchPage
    , activeSearchServer
    )
import Examples.Animations
    ( AnimationsAPI
    , animationsPage
    , animationsServer
    )
import Examples.BulkUpdate
    ( BulkUpdateAPI
    , bulkUpdatePage
    , bulkUpdateServer
    , defaultItems
    )
import Examples.ClickToEdit
    ( ClickToEditAPI
    , clickToEditPage
    , clickToEditServer
    , defaultContact
    )
import Examples.ClickToLoad
    ( ClickToLoadAPI
    , clickToLoadPage
    , clickToLoadServer
    )
import Examples.DeleteRow
    ( DeleteRowAPI
    , defaultContacts
    , deleteRowPage
    , deleteRowServer
    )
import Examples.EditRow
    ( EditRowAPI
    , editRowPage
    , editRowServer
    )
import Examples.EditRow qualified as EditRow
import Examples.FileUpload
    ( FileUploadAPI
    , fileUploadPage
    , fileUploadServer
    )
import Examples.Index qualified as Index
import Examples.InfiniteScroll
    ( InfiniteScrollAPI
    , infiniteScrollPage
    , infiniteScrollServer
    )
import Examples.InlineValidation
    ( InlineValidationAPI
    , inlineValidationPage
    , inlineValidationServer
    )
import Examples.LazyLoad
    ( LazyLoadAPI
    , lazyLoadPage
    , lazyLoadServer
    )
import Examples.LazyTabs
    ( LazyTabsAPI
    , lazyTabsPage
    , lazyTabsServer
    )
import Examples.ProgressBar
    ( ProgressBarAPI
    , progressBarPage
    , progressBarServer
    )
import Examples.TodoMVC
    ( TodoMVCAPI
    , defaultState
    , todoMVCPage
    , todoMVCServer
    )
import Layout (HTML)

type PageRoute = Get '[HTML] LBS.ByteString

type ExamplesAPI =
    PageRoute
        :<|> "examples"
            :> ( "click-to-edit"
                    :> ( PageRoute
                            :<|> "data" :> ClickToEditAPI
                       )
                    :<|> "delete-row"
                        :> ( PageRoute
                                :<|> "data" :> DeleteRowAPI
                           )
                    :<|> "edit-row"
                        :> ( PageRoute
                                :<|> "data" :> EditRowAPI
                           )
                    :<|> "bulk-update"
                        :> ( PageRoute
                                :<|> "data"
                                    :> BulkUpdateAPI
                           )
                    :<|> "active-search"
                        :> ( PageRoute
                                :<|> "data"
                                    :> ActiveSearchAPI
                           )
                    :<|> "inline-validation"
                        :> ( PageRoute
                                :<|> "data"
                                    :> InlineValidationAPI
                           )
                    :<|> "click-to-load"
                        :> ( PageRoute
                                :<|> "data"
                                    :> ClickToLoadAPI
                           )
                    :<|> "infinite-scroll"
                        :> ( PageRoute
                                :<|> "data"
                                    :> InfiniteScrollAPI
                           )
                    :<|> "lazy-load"
                        :> ( PageRoute
                                :<|> "data" :> LazyLoadAPI
                           )
                    :<|> "lazy-tabs"
                        :> ( PageRoute
                                :<|> "data" :> LazyTabsAPI
                           )
                    :<|> "progress-bar"
                        :> ( PageRoute
                                :<|> "data"
                                    :> ProgressBarAPI
                           )
                    :<|> "file-upload"
                        :> ( PageRoute
                                :<|> "data"
                                    :> FileUploadAPI
                           )
                    :<|> "animations"
                        :> ( PageRoute
                                :<|> "data"
                                    :> AnimationsAPI
                           )
                    :<|> "todo"
                        :> ( PageRoute
                                :<|> "data" :> TodoMVCAPI
                           )
               )

servePage :: Html () -> Handler LBS.ByteString
servePage = pure . renderBS

main :: IO ()
main = do
    port <-
        maybe 3000 read <$> lookupEnv "PORT"

    clickToEditRef <- newIORef defaultContact
    deleteRowRef <- newIORef defaultContacts
    editRowRef <- newIORef EditRow.defaultContacts
    bulkUpdateRef <- newIORef defaultItems
    clickToLoadRef <- newIORef (0 :: Int)
    infiniteScrollRef <- newIORef (0 :: Int)
    progressBarRef <- newIORef (0 :: Int)
    todoRef <- newIORef defaultState

    putStrLn $
        "Listening on http://localhost:"
            <> show port
    Warp.run port $
        serve (Proxy :: Proxy ExamplesAPI) $
            servePage Index.indexPage
                :<|> ( ( servePage clickToEditPage
                            :<|> clickToEditServer
                                clickToEditRef
                       )
                        :<|> ( servePage deleteRowPage
                                :<|> deleteRowServer
                                    deleteRowRef
                             )
                        :<|> ( servePage editRowPage
                                :<|> editRowServer
                                    editRowRef
                             )
                        :<|> ( servePage bulkUpdatePage
                                :<|> bulkUpdateServer
                                    bulkUpdateRef
                             )
                        :<|> ( servePage
                                activeSearchPage
                                :<|> activeSearchServer
                             )
                        :<|> ( servePage
                                inlineValidationPage
                                :<|> inlineValidationServer
                             )
                        :<|> ( servePage
                                clickToLoadPage
                                :<|> clickToLoadServer
                                    clickToLoadRef
                             )
                        :<|> ( servePage
                                infiniteScrollPage
                                :<|> infiniteScrollServer
                                    infiniteScrollRef
                             )
                        :<|> ( servePage lazyLoadPage
                                :<|> lazyLoadServer
                             )
                        :<|> ( servePage lazyTabsPage
                                :<|> lazyTabsServer
                             )
                        :<|> ( servePage
                                progressBarPage
                                :<|> progressBarServer
                                    progressBarRef
                             )
                        :<|> ( servePage fileUploadPage
                                :<|> fileUploadServer
                             )
                        :<|> ( servePage animationsPage
                                :<|> animationsServer
                             )
                        :<|> ( servePage todoMVCPage
                                :<|> todoMVCServer
                                    todoRef
                             )
                     )
