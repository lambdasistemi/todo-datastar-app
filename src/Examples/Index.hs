module Examples.Index
    ( indexPage
    ) where

import Data.Text (Text)
import Layout (page)
import Lucid

-- | Index page listing all examples
indexPage :: Html ()
indexPage = page "Datastar Examples" $ do
    h1_ "Datastar Examples"
    p_
        "Haskell implementations using Servant \
        \+ Lucid + datastar-lucid DSL."
    ul_ $ mapM_ exampleLink examples

exampleLink :: (Text, Text) -> Html ()
exampleLink (path, name) =
    li_ $ a_ [href_ path] $ toHtml name

examples :: [(Text, Text)]
examples =
    [ ("/examples/click-to-edit", "Click To Edit")
    , ("/examples/delete-row", "Delete Row")
    , ("/examples/edit-row", "Edit Row")
    , ("/examples/bulk-update", "Bulk Update")
    , ("/examples/active-search", "Active Search")
    ,
        ( "/examples/inline-validation"
        , "Inline Validation"
        )
    , ("/examples/click-to-load", "Click To Load")
    ,
        ( "/examples/infinite-scroll"
        , "Infinite Scroll"
        )
    , ("/examples/lazy-load", "Lazy Load")
    , ("/examples/lazy-tabs", "Lazy Tabs")
    , ("/examples/progress-bar", "Progress Bar")
    , ("/examples/file-upload", "File Upload")
    , ("/examples/animations", "Animations")
    , ("/examples/todo", "TodoMVC")
    ]
