module Main (main) where

import Control.Monad.IO.Class (liftIO)
import Data.ByteString.Lazy qualified as LBS
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text.Lazy qualified as LT
import Data.Text.Lazy.Encoding qualified as TLE
import Database.SQLite3 qualified as SQL
import Network.Wai (Application)
import Network.Wai.Handler.Warp qualified as Warp
import Servant
    ( Handler
    , Proxy (..)
    , serve
    , (:<|>) (..)
    )
import System.Environment (lookupEnv)
import Todo.API (API, Signals (..))
import Todo.DB qualified as DB
import Todo.HTML (indexPage, renderTodoList)
import Todo.Types (TodoId)

main :: IO ()
main = do
    port <- maybe 3000 read <$> lookupEnv "PORT"
    dbPath <-
        fromMaybe "todos.db" <$> lookupEnv "DB_PATH"
    DB.withDB dbPath $ \db -> do
        putStrLn $
            "Listening on http://localhost:"
                <> show port
        Warp.run port (app db)

app :: SQL.Database -> Application
app db =
    serve (Proxy :: Proxy API) $
        serveIndex
            :<|> getTodos db
            :<|> postTodo db
            :<|> toggleTodo db
            :<|> deleteTodo db

serveIndex :: Handler LBS.ByteString
serveIndex =
    pure $ TLE.encodeUtf8 indexPage

getTodos :: SQL.Database -> Handler Text
getTodos db =
    liftIO $
        LT.toStrict . renderTodoList <$> DB.listTodos db

postTodo
    :: SQL.Database
    -> Signals
    -> Handler Text
postTodo db (Signals txt) = liftIO $ do
    DB.addTodo db txt
    LT.toStrict . renderTodoList <$> DB.listTodos db

toggleTodo
    :: SQL.Database
    -> TodoId
    -> Handler Text
toggleTodo db tid = liftIO $ do
    DB.toggleTodo db tid
    LT.toStrict . renderTodoList <$> DB.listTodos db

deleteTodo
    :: SQL.Database
    -> TodoId
    -> Handler Text
deleteTodo db tid = liftIO $ do
    DB.deleteTodo db tid
    LT.toStrict . renderTodoList <$> DB.listTodos db
