module Examples.ActiveSearch
    ( ActiveSearchAPI
    , activeSearchServer
    , activeSearchPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Aeson (FromJSON)
import Data.Text (Text, isInfixOf, toLower)
import GHC.Generics (Generic)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:>))
import Servant.Datastar
    ( DatastarPatch
    , DatastarSignals
    , StdMethod (..)
    )

newtype SearchSignals = SearchSignals
    { search :: Text
    }
    deriving (Generic)
    deriving anyclass (FromJSON)

type ActiveSearchAPI =
    "results"
        :> DatastarSignals SearchSignals
        :> DatastarPatch 'GET

activeSearchPage :: Html ()
activeSearchPage = examplePage "Active Search" $
    div_ [id_ "demo"] $ do
        input_
            ( [ type_ "search"
              , placeholder_ "Search contacts..."
              ]
                <> datastar
                    ( do
                        signal "search" "''"
                        bind "search"
                        on "input" [Debounce "200ms"] $
                            act $
                                get
                                    ( base
                                        <> "/results"
                                    )
                    )
            )
        div_ [id_ "results"] mempty

activeSearchServer :: SearchSignals -> Handler Text
activeSearchServer (SearchSignals q) =
    liftIO $
        pure $
            render $
                resultsHtml $
                    filterContacts q

base :: Text
base = "/examples/active-search/data"

data Contact = Contact
    { contactName :: Text
    , contactEmail :: Text
    }

allContacts :: [Contact]
allContacts =
    [ Contact "Joe Smith" "joe@smith.org"
    , Contact "Angie MacDowell" "angie@macdowell.org"
    , Contact "Fuqua Tarkenton" "fuqua@tarkenton.org"
    , Contact "Kim Yee" "kim@yee.org"
    , Contact "Jane Doe" "jane@doe.org"
    , Contact "Bob Jones" "bob@jones.org"
    ]

filterContacts :: Text -> [Contact]
filterContacts "" = allContacts
filterContacts q =
    filter (matches (toLower q)) allContacts
  where
    matches q' Contact{contactName, contactEmail} =
        q'
            `isInfixOf` toLower contactName
            || q'
                `isInfixOf` toLower contactEmail

resultsHtml :: [Contact] -> Html ()
resultsHtml contacts =
    div_ [id_ "results"] $
        table_ $ do
            thead_ $
                tr_ $ do
                    th_ "Name"
                    th_ "Email"
            tbody_ $
                mapM_ rowHtml contacts

rowHtml :: Contact -> Html ()
rowHtml Contact{contactName, contactEmail} =
    tr_ $ do
        td_ $ toHtml contactName
        td_ $ toHtml contactEmail
