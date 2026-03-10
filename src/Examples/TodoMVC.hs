module Examples.TodoMVC
    ( TodoMVCAPI
    , todoMVCServer
    , todoMVCPage
    , defaultState
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.IORef
    ( IORef
    , modifyIORef'
    , readIORef
    , writeIORef
    )
import Data.List.Extra (collect, item, items, when')
import Data.Text (Text, pack)
import GHC.Generics (Generic)
import Layout (examplePage, render)
import Lucid
import Lucid.Base (makeAttribute)
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

data TodoItem = TodoItem
    { tdId :: Int
    , tdText :: Text
    , tdDone :: Bool
    }

data FilterMode = All | Pending | Completed
    deriving (Eq)

data TodoState = TodoState
    { tsItems :: [TodoItem]
    , tsNextId :: Int
    , tsMode :: FilterMode
    }

newtype AddSignals = AddSignals {input :: Text}
    deriving (Generic)
    deriving anyclass (FromJSON)

type TodoMVCAPI =
    DatastarPatch 'GET
        :<|> Capture "id" Int
            :> DatastarSignals AddSignals
            :> DatastarPatch 'PATCH
        :<|> Capture "id" Int
            :> "toggle"
            :> DatastarPatch 'POST
        :<|> Capture "id" Int
            :> DatastarPatch 'DELETE
        :<|> "mode"
            :> Capture "mode" Int
            :> DatastarPatch 'PUT
        :<|> "reset"
            :> DatastarPatch 'PUT
        :<|> "delete-completed"
            :> DatastarPatch 'DELETE

defaultTodos :: [TodoItem]
defaultTodos =
    [ TodoItem 0 "Learn any backend language" True
    , TodoItem 1 "Learn Datastar" False
    , TodoItem 2 "???" False
    , TodoItem 3 "Profit" False
    ]

defaultState :: TodoState
defaultState =
    TodoState
        { tsItems = defaultTodos
        , tsNextId = 4
        , tsMode = All
        }

todoMVCPage :: Html ()
todoMVCPage = examplePage "TodoMVC"
    $ section_
        ( [id_ "todomvc"]
            <> datastar
                (onInit $ act $ get base)
        )
    $ do
        todoFormHtml
        ul_ [id_ "todo-list"] mempty
        actionsHtml defaultState

todoMVCServer
    :: IORef TodoState
    -> Handler Text
        :<|> (Int -> AddSignals -> Handler Text)
        :<|> (Int -> Handler Text)
        :<|> (Int -> Handler Text)
        :<|> (Int -> Handler Text)
        :<|> Handler Text
        :<|> Handler Text
todoMVCServer ref =
    getTodos ref
        :<|> addTodo ref
        :<|> toggleTodo ref
        :<|> deleteTodo ref
        :<|> setMode ref
        :<|> resetTodos ref
        :<|> deleteCompleted ref

base :: Text
base = "/examples/todo/data"

getTodos :: IORef TodoState -> Handler Text
getTodos ref = liftIO $ do
    st <- readIORef ref
    pure $ render $ viewHtml st

addTodo :: IORef TodoState -> Int -> AddSignals -> Handler Text
addTodo ref _id (AddSignals txt) = liftIO $ do
    modifyIORef' ref $ \st ->
        st
            { tsItems =
                tsItems st
                    ++ [ TodoItem
                            (tsNextId st)
                            txt
                            False
                       ]
            , tsNextId = tsNextId st + 1
            }
    render . viewHtml <$> readIORef ref

toggleTodo :: IORef TodoState -> Int -> Handler Text
toggleTodo ref tid = liftIO $ do
    modifyIORef' ref $ \st ->
        if tid == -1
            then
                let allDone = all tdDone (tsItems st)
                in  st
                        { tsItems =
                            fmap
                                (\t -> t{tdDone = not allDone})
                                (tsItems st)
                        }
            else
                st
                    { tsItems =
                        fmap
                            ( \t ->
                                if tdId t == tid
                                    then t{tdDone = not (tdDone t)}
                                    else t
                            )
                            (tsItems st)
                    }
    render . viewHtml <$> readIORef ref

deleteTodo :: IORef TodoState -> Int -> Handler Text
deleteTodo ref tid = liftIO $ do
    modifyIORef' ref $ \st ->
        st
            { tsItems =
                filter
                    (\t -> tdId t /= tid)
                    (tsItems st)
            }
    render . viewHtml <$> readIORef ref

setMode :: IORef TodoState -> Int -> Handler Text
setMode ref m = liftIO $ do
    modifyIORef' ref $ \st ->
        st{tsMode = intToMode m}
    render . viewHtml <$> readIORef ref
  where
    intToMode 1 = Pending
    intToMode 2 = Completed
    intToMode _ = All

resetTodos :: IORef TodoState -> Handler Text
resetTodos ref = liftIO $ do
    writeIORef ref defaultState
    render . viewHtml <$> readIORef ref

deleteCompleted :: IORef TodoState -> Handler Text
deleteCompleted ref = liftIO $ do
    modifyIORef' ref $ \st ->
        st
            { tsItems =
                filter
                    (not . tdDone)
                    (tsItems st)
            }
    render . viewHtml <$> readIORef ref

viewHtml :: TodoState -> Html ()
viewHtml st = do
    listHtml (tsMode st) (tsItems st)
    actionsHtml st

todoFormHtml :: Html ()
todoFormHtml =
    header_ [id_ "todo-header"] $ do
        input_
            ( collect $ do
                item $ type_ "checkbox"
                items $
                    datastar $ do
                        on "click" [Prevent] $
                            act $
                                post (base <> "/-1/toggle")
                        onInit $ raw "el.checked = false"
            )
        input_
            ( collect $ do
                item $ id_ "new-todo"
                item $ type_ "text"
                item $
                    placeholder_
                        "What needs to be done?"
                items $
                    datastar $ do
                        signal "input" ""
                        bind "input"
                        on "keydown" [] $
                            raw "evt.key === 'Enter'"
                                &&. raw "$input.trim()"
                                &&. act (patch (base <> "/-1"))
                                &&. raw "($input = '')"
            )

listHtml :: FilterMode -> [TodoItem] -> Html ()
listHtml mode todos =
    ul_ [id_ "todo-list"] $
        mapM_ todoItemHtml (filterTodos mode todos)

filterTodos :: FilterMode -> [TodoItem] -> [TodoItem]
filterTodos All = id
filterTodos Pending = filter (not . tdDone)
filterTodos Completed = filter tdDone

todoItemHtml :: TodoItem -> Html ()
todoItemHtml TodoItem{tdId, tdText, tdDone} =
    li_
        [ id_ ("todo-" <> showT tdId)
        , class_ "todo-item"
        ]
        $ button_
            ( collect $ do
                item $ role_ "button"
                item $ class_ "outline"
            )
        $ do
            input_
                ( collect $ do
                    item $ type_ "checkbox"
                    item $
                        makeAttribute
                            "aria-label"
                            tdText
                    when' tdDone $ item checked_
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    post
                                        ( base
                                            <> "/"
                                            <> showT tdId
                                            <> "/toggle"
                                        )
                )
            span_
                [ style_
                    ( if tdDone
                        then
                            "text-decoration:"
                                <> "line-through"
                        else ""
                    )
                ]
                $ toHtml tdText

actionsHtml :: TodoState -> Html ()
actionsHtml TodoState{tsItems, tsMode} =
    div_ [id_ "todo-actions"] $ do
        span_ $ do
            strong_ $ toHtml $ showT pending
            " items pending"
        modeBtn "All" (0 :: Int) (tsMode == All)
        modeBtn "Pending" (1 :: Int) (tsMode == Pending)
        modeBtn "Completed" (2 :: Int) (tsMode == Completed)
        let hasCompleted = any tdDone tsItems
        button_
            ( collect $ do
                item $ class_ "error small"
                if hasCompleted
                    then
                        items $
                            datastar $
                                on "click" [] $
                                    act $
                                        delete
                                            ( base
                                                <> "/delete-completed"
                                            )
                    else
                        item $
                            makeAttribute
                                "aria-disabled"
                                "true"
            )
            "Delete"
        button_
            ( collect $ do
                item $ class_ "warning small"
                items $
                    datastar $
                        on "click" [] $
                            act $
                                put (base <> "/reset")
            )
            "Reset"
  where
    pending = length $ filter (not . tdDone) tsItems
    modeBtn label m active =
        button_
            ( collect $ do
                item $
                    class_
                        ( "small"
                            <> if active
                                then " info"
                                else ""
                        )
                items $
                    datastar $
                        on "click" [] $
                            act $
                                put
                                    ( base
                                        <> "/mode/"
                                        <> showT m
                                    )
            )
            label

showT :: (Show a) => a -> Text
showT = pack . show
