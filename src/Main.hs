module Main (main) where

import Data.Aeson (FromJSON)
import Data.ByteString.Lazy qualified as LBS
import Data.Text (Text, unpack)
import Data.Text.Encoding qualified as TE
import Database.SQLite3 qualified as SQL
import GHC.Generics (Generic)
import Hypermedia.Datastar
    ( nullLogger
    , patchElements
    , readSignals
    , sendPatchElements
    , sseResponse
    )
import Network.HTTP.Types
    ( status200
    , status400
    , status404
    )
import Network.Wai
    ( Application
    , Response
    , pathInfo
    , requestMethod
    , responseLBS
    )
import Network.Wai.Handler.Warp qualified as Warp
import System.Environment (lookupEnv)
import Text.Read (readMaybe)
import Todo.DB
    ( addTodo
    , deleteTodo
    , listTodos
    , toggleTodo
    , withDB
    )
import Todo.HTML (indexPage, renderTodoList)
import Todo.Types (TodoId)

newtype Signals = Signals {input :: Text}
    deriving (Generic)
    deriving anyclass (FromJSON)

main :: IO ()
main = do
    port <- maybe 3000 read <$> lookupEnv "PORT"
    dbPath <-
        maybe "todos.db" id <$> lookupEnv "DB_PATH"
    withDB dbPath $ \db -> do
        putStrLn $
            "Listening on http://localhost:"
                <> show port
        Warp.run port (app db)

app :: SQL.Database -> Application
app db req respond =
    case (requestMethod req, pathInfo req) of
        ("GET", []) ->
            respond $
                responseLBS
                    status200
                    [("Content-Type", "text/html")]
                    ( LBS.fromStrict $
                        TE.encodeUtf8 indexPage
                    )
        ("GET", ["todos"]) ->
            sendTodoList db respond
        ("POST", ["todos"]) -> do
            result <- readSignals req
            case result of
                Right (Signals txt) | txt /= "" -> do
                    addTodo db txt
                    sendTodoList db respond
                _ ->
                    respond $
                        responseLBS
                            status400
                            []
                            "Bad input"
        ("PATCH", ["todos", tid, "toggle"]) ->
            withTodoId tid respond $ \todoId -> do
                toggleTodo db todoId
                sendTodoList db respond
        ("DELETE", ["todos", tid]) ->
            withTodoId tid respond $ \todoId -> do
                deleteTodo db todoId
                sendTodoList db respond
        _ ->
            respond $
                responseLBS status404 [] "Not found"

-- | Parse a todo ID from a URL segment
withTodoId
    :: Text
    -> (Response -> IO b)
    -> (TodoId -> IO b)
    -> IO b
withTodoId tidText respond action =
    case readMaybe (unpack tidText) of
        Just tid -> action tid
        Nothing ->
            respond $
                responseLBS status400 [] "Bad id"

-- | Send the full todo list as an SSE response
sendTodoList
    :: SQL.Database
    -> (Response -> IO b)
    -> IO b
sendTodoList db respond = do
    todos <- listTodos db
    respond $ sseResponse nullLogger $ \gen ->
        sendPatchElements gen $
            patchElements (renderTodoList todos)
