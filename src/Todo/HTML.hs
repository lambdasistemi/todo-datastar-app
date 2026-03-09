module Todo.HTML
    ( indexPage
    , todoList
    ) where

import Clay qualified
import Data.List.Extra (collect, item, items, when')
import Data.Text (Text, pack)
import Data.Text.Lazy qualified as LT
import Lucid
import Lucid.Datastar
import Todo.CSS (todoCss)
import Todo.Types (Todo (..), TodoId)

-- | Full HTML page served on GET /
indexPage :: Html ()
indexPage = doctypehtml_ $ do
    head_ $ do
        meta_ [charset_ "utf-8"]
        meta_
            [ name_ "viewport"
            , content_
                "width=device-width, initial-scale=1"
            ]
        title_ "Todo"
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
        style_ $ LT.toStrict $ Clay.render todoCss
    body_ $
        main_ [class_ "container"] $ do
            h1_ "Todo"
            todoForm
            ul_
                ( collect $ do
                    item $ id_ "todo-list"
                    items $
                        datastar $
                            onInit $
                                act $
                                    get "/todos"
                )
                mempty

-- | The full todo list
todoList :: [Todo] -> Html ()
todoList todos =
    ul_ [id_ "todo-list"] $
        mapM_ renderTodoItem todos

-- | Render a single todo item
renderTodoItem :: (Monad m) => Todo -> HtmlT m ()
renderTodoItem Todo{todoId, todoText, todoDone} =
    li_
        [ id_ ("todo-" <> showT todoId)
        , class_
            ( "todo-item"
                <> if todoDone
                    then " done"
                    else ""
            )
        ]
        $ do
            input_
                ( collect $ do
                    item $ type_ "checkbox"
                    when' todoDone $ item checked_
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    patch toggleUrl
                )
            label_
                ( datastar $
                    on "click" [] $
                        act $
                            patch toggleUrl
                )
                $ toHtml todoText
            button_
                ( collect $ do
                    item $ class_ "outline secondary"
                    items $
                        datastar $
                            on "click" [] $
                                act $
                                    delete todoUrl
                )
                "\215"
  where
    toggleUrl =
        "/todos/" <> showT todoId <> "/toggle"
    todoUrl = "/todos/" <> showT todoId

-- | The add-todo form
todoForm :: (Monad m) => HtmlT m ()
todoForm =
    form_
        ( datastar $ do
            signal "input" "''"
            on "submit" [Prevent] $
                raw "$input.trim()"
                    &&. act (post "/todos")
                    &&. assign "input" (raw "''")
        )
        $ fieldset_ [role_ "group"]
        $ do
            input_
                ( collect $ do
                    item $ type_ "text"
                    item $
                        placeholder_
                            "What needs to be done?"
                    item $ autocomplete_ "off"
                    items $ datastar $ bind "input"
                )
            button_ [type_ "submit"] "Add"

showT :: TodoId -> Text
showT = pack . show
