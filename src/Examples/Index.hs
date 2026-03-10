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
    p_ $ do
        "Haskell implementations using Servant \
        \+ Lucid + datastar-lucid DSL. "
        a_
            [ href_
                "https://github.com/lambdasistemi\
                \/datastar-examples"
            ]
            "Source on GitHub"
        "."
    ul_ $ mapM_ exampleLink examples

exampleLink :: (Text, Text, Text) -> Html ()
exampleLink (path, name, source) =
    li_ $ do
        a_ [href_ path] $ toHtml name
        " ("
        a_ [href_ (srcBase <> source)] "source"
        ")"

srcBase :: Text
srcBase =
    "https://github.com/lambdasistemi\
    \/datastar-examples/blob/main/src/Examples/"

examples :: [(Text, Text, Text)]
examples =
    [ ("/examples/click-to-edit", "Click To Edit", "ClickToEdit.hs")
    , ("/examples/delete-row", "Delete Row", "DeleteRow.hs")
    , ("/examples/edit-row", "Edit Row", "EditRow.hs")
    , ("/examples/bulk-update", "Bulk Update", "BulkUpdate.hs")
    , ("/examples/active-search", "Active Search", "ActiveSearch.hs")
    ,
        ( "/examples/inline-validation"
        , "Inline Validation"
        , "InlineValidation.hs"
        )
    , ("/examples/click-to-load", "Click To Load", "ClickToLoad.hs")
    , ("/examples/infinite-scroll", "Infinite Scroll", "InfiniteScroll.hs")
    , ("/examples/lazy-load", "Lazy Load", "LazyLoad.hs")
    , ("/examples/lazy-tabs", "Lazy Tabs", "LazyTabs.hs")
    , ("/examples/progress-bar", "Progress Bar", "ProgressBar.hs")
    , ("/examples/file-upload", "File Upload", "FileUpload.hs")
    , ("/examples/animations", "Animations", "Animations.hs")
    , ("/examples/todo", "TodoMVC", "TodoMVC.hs")
    ]
