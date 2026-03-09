module Todo.DB
    ( withDB
    , addTodo
    , toggleTodo
    , deleteTodo
    , listTodos
    ) where

import Data.Text (Text, pack)
import Database.SQLite3 qualified as SQL
import Todo.Types (Todo (..), TodoId)

-- | Open the database and run an action with it
withDB :: FilePath -> (SQL.Database -> IO a) -> IO a
withDB path action = do
    db <- SQL.open (pack path)
    SQL.exec
        db
        "CREATE TABLE IF NOT EXISTS todos (\
        \  id INTEGER PRIMARY KEY AUTOINCREMENT,\
        \  text TEXT NOT NULL,\
        \  done INTEGER NOT NULL DEFAULT 0\
        \)"
    result <- action db
    SQL.close db
    pure result

-- | Add a new todo item
addTodo :: SQL.Database -> Text -> IO ()
addTodo db txt = do
    stmt <-
        SQL.prepare
            db
            "INSERT INTO todos (text, done) VALUES (?, 0)"
    SQL.bindSQLData stmt 1 (SQL.SQLText txt)
    _ <- SQL.step stmt
    SQL.finalize stmt

-- | Toggle the done status of a todo
toggleTodo :: SQL.Database -> TodoId -> IO ()
toggleTodo db tid = do
    stmt <-
        SQL.prepare
            db
            "UPDATE todos SET done = 1 - done \
            \WHERE id = ?"
    SQL.bindSQLData
        stmt
        1
        (SQL.SQLInteger (fromIntegral tid))
    _ <- SQL.step stmt
    SQL.finalize stmt

-- | Delete a todo
deleteTodo :: SQL.Database -> TodoId -> IO ()
deleteTodo db tid = do
    stmt <-
        SQL.prepare
            db
            "DELETE FROM todos WHERE id = ?"
    SQL.bindSQLData
        stmt
        1
        (SQL.SQLInteger (fromIntegral tid))
    _ <- SQL.step stmt
    SQL.finalize stmt

-- | List all todos
listTodos :: SQL.Database -> IO [Todo]
listTodos db = do
    stmt <-
        SQL.prepare
            db
            "SELECT id, text, done \
            \FROM todos ORDER BY id"
    go stmt []
  where
    go stmt acc = do
        r <- SQL.step stmt
        case r of
            SQL.Row -> do
                tid <- SQL.columnInt64 stmt 0
                txt <- SQL.columnText stmt 1
                done <- SQL.columnInt64 stmt 2
                let todo =
                        Todo
                            { todoId = fromIntegral tid
                            , todoText = txt
                            , todoDone = done /= 0
                            }
                go stmt (acc ++ [todo])
            SQL.Done -> do
                SQL.finalize stmt
                pure acc
