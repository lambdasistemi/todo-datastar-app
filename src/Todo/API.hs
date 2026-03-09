module Todo.API
    ( API
    , HTML
    , Signals (..)
    ) where

import Data.Aeson (FromJSON)
import Data.ByteString.Lazy qualified as LBS
import Data.Text (Text)
import GHC.Generics (Generic)
import Network.HTTP.Media ((//))
import Network.HTTP.Types (StdMethod (..))
import Servant.API
    ( Capture
    , Get
    , MimeRender (..)
    , (:<|>)
    , (:>)
    )
import Servant.API.ContentTypes (Accept (..))
import Servant.Datastar
    ( DatastarPatch
    , DatastarSignals
    )
import Todo.Types (TodoId)

-- | HTML content type for serving pages
data HTML

instance Accept HTML where
    contentType _ = "text" // "html"

instance MimeRender HTML LBS.ByteString where
    mimeRender _ = id

-- | Signals sent from the add-todo form
newtype Signals = Signals {input :: Text}
    deriving (Generic)
    deriving anyclass (FromJSON)

-- | Servant API type for the todo app
type API =
    Get '[HTML] LBS.ByteString
        :<|> "todos" :> DatastarPatch 'GET
        :<|> "todos"
            :> DatastarSignals Signals
            :> DatastarPatch 'POST
        :<|> "todos"
            :> Capture "id" TodoId
            :> "toggle"
            :> DatastarPatch 'PATCH
        :<|> "todos"
            :> Capture "id" TodoId
            :> DatastarPatch 'DELETE
