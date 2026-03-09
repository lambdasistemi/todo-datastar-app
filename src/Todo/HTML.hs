module Todo.HTML
    ( indexPage
    , renderTodoList
    ) where

import Data.Text
    ( Text
    , concatMap
    , pack
    , singleton
    )
import Prelude hiding (concatMap)
import Todo.Types (Todo (..), TodoId)

-- | Full HTML page served on GET /
indexPage :: Text
indexPage =
    "<!DOCTYPE html>\
    \<html lang=\"en\" data-theme=\"dark\">\
    \<head>\
    \  <meta charset=\"utf-8\">\
    \  <meta name=\"viewport\"\
    \    content=\"width=device-width, initial-scale=1\">\
    \  <title>Todo</title>\
    \  <link rel=\"stylesheet\"\
    \    href=\"https://cdn.jsdelivr.net/npm/\
    \@picocss/pico@2/css/pico.min.css\">\
    \  <script type=\"module\"\
    \    src=\"https://cdn.jsdelivr.net/gh/\
    \starfederation/datastar@1.0.0-RC.8/\
    \bundles/datastar.js\"></script>\
    \  <style>\
    \    .done { text-decoration: line-through;\
    \            opacity: 0.6; }\
    \    .todo-item { display: flex;\
    \                 align-items: center;\
    \                 gap: 0.5rem;\
    \                 padding: 0.5rem 0; }\
    \    .todo-item label { flex: 1; margin: 0;\
    \                       cursor: pointer; }\
    \    .todo-item button { width: auto;\
    \                        margin: 0;\
    \                        padding: 0.25rem 0.5rem; }\
    \    #todo-list { list-style: none;\
    \                 padding: 0; }\
    \  </style>\
    \</head>\
    \<body>\
    \  <main class=\"container\">\
    \    <h1>Todo</h1>\
    \    <form data-signals:input=\"''\"\
    \          data-on:submit__prevent=\"\
    \            $input.trim() &&\
    \            @post('/todos') &&\
    \            ($input = '')\">\
    \      <fieldset role=\"group\">\
    \        <input type=\"text\"\
    \               placeholder=\"What needs to be done?\"\
    \               data-bind:input\
    \               autocomplete=\"off\">\
    \        <button type=\"submit\">Add</button>\
    \      </fieldset>\
    \    </form>\
    \    <ul id=\"todo-list\"\
    \        data-on:load=\"@get('/todos')\">\
    \    </ul>\
    \  </main>\
    \</body>\
    \</html>"

-- | Render the full todo list as HTML
renderTodoList :: [Todo] -> Text
renderTodoList todos =
    "<ul id=\"todo-list\">"
        <> foldMap renderTodoItem todos
        <> "</ul>"

-- | Render a single todo item
renderTodoItem :: Todo -> Text
renderTodoItem Todo{todoId, todoText, todoDone} =
    "<li id=\"todo-"
        <> showT todoId
        <> "\" class=\"todo-item"
        <> (if todoDone then " done" else "")
        <> "\">"
        <> "<input type=\"checkbox\""
        <> (if todoDone then " checked" else "")
        <> " data-on:click=\"@patch('/todos/"
        <> showT todoId
        <> "/toggle')\">"
        <> "<label data-on:click=\"@patch('/todos/"
        <> showT todoId
        <> "/toggle')\">"
        <> escapeHtml todoText
        <> "</label>"
        <> "<button class=\"outline secondary\"\
           \ data-on:click=\"@delete('/todos/"
        <> showT todoId
        <> "')\">\
           \&times;</button>"
        <> "</li>"

showT :: TodoId -> Text
showT = pack . show

-- | Escape HTML special characters
escapeHtml :: Text -> Text
escapeHtml = concatMap escapeChar
  where
    escapeChar '<' = "&lt;"
    escapeChar '>' = "&gt;"
    escapeChar '&' = "&amp;"
    escapeChar '"' = "&quot;"
    escapeChar c = singleton c
