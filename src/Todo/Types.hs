module Todo.Types
    ( Todo (..)
    , TodoId
    ) where

import Data.Text (Text)

-- | Unique identifier for a todo item
type TodoId = Int

-- | A single todo item
data Todo = Todo
    { todoId :: TodoId
    , todoText :: Text
    , todoDone :: Bool
    }
    deriving (Show, Eq)
