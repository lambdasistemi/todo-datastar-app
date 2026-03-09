module Todo.CSS
    ( todoCss
    ) where

import Clay
import Prelude hiding (rem)

todoCss :: Css
todoCss = do
    ".done" ? do
        textDecoration lineThrough
        opacity 0.6
    ".todo-item" ? do
        display flex
        alignItems center
        "gap" -: "0.5rem"
        paddingTop (rem 0.5)
        paddingBottom (rem 0.5)
    ".todo-item" |> label ? do
        "flex" -: "1"
        margin nil nil nil nil
        cursor pointer
    ".todo-item" |> button ? do
        width auto
        margin nil nil nil nil
        paddingTop (rem 0.25)
        paddingBottom (rem 0.25)
        paddingLeft (rem 0.5)
        paddingRight (rem 0.5)
    "#todo-list" ? do
        listStyleType none
        padding nil nil nil nil
