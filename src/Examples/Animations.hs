module Examples.Animations
    ( AnimationsAPI
    , animationsServer
    , animationsPage
    ) where

import Control.Monad.IO.Class (liftIO)
import Data.Text (Text, pack)
import Layout (examplePage, render)
import Lucid
import Lucid.Datastar
import Servant (Handler, (:<|>) (..), (:>))
import Servant.Datastar (DatastarPatch, StdMethod (..))
import System.Random (randomRIO)

type AnimationsAPI =
    DatastarPatch 'GET
        :<|> "shuffle"
            :> DatastarPatch 'GET

animationsPage :: Html ()
animationsPage = examplePage "Animations" $
    div_ [id_ "demo"] $ do
        p_
            "Animations use CSS transitions \
            \combined with datastar's view \
            \transition support."
        div_
            ( [id_ "content"]
                <> datastar
                    ( onInit $
                        act $
                            get base
                    )
            )
            mempty
        button_
            ( datastar $
                on "click" [] $
                    act $
                        get (base <> "/shuffle")
            )
            "Shuffle"

animationsServer
    :: Handler Text :<|> Handler Text
animationsServer =
    getContent :<|> shuffleContent

base :: Text
base = "/examples/animations/data"

colors :: [Text]
colors =
    [ "#e74c3c"
    , "#3498db"
    , "#2ecc71"
    , "#f39c12"
    , "#9b59b6"
    ]

getContent :: Handler Text
getContent = liftIO $ pure $ render $ colorList colors

shuffleContent :: Handler Text
shuffleContent = liftIO $ do
    shuffled <- shuffle colors
    pure $ render $ colorList shuffled

shuffle :: [a] -> IO [a]
shuffle [] = pure []
shuffle [x] = pure [x]
shuffle xs = do
    i <- randomRIO (0, length xs - 1)
    let (picked, rest) = removeAt i xs
    (picked :) <$> shuffle rest

removeAt :: Int -> [a] -> (a, [a])
removeAt i xs =
    case splitAt i xs of
        (before, x : after) ->
            (x, before ++ after)
        _ -> error "removeAt: index out of bounds"

colorList :: [Text] -> Html ()
colorList cs =
    div_ [id_ "content"] $
        mapM_ colorBox (zip [(0 :: Int) ..] cs)

colorBox :: (Int, Text) -> Html ()
colorBox (idx, color) =
    div_
        [ style_ $
            "background:"
                <> color
                <> ";padding:1rem;\
                   \margin:0.5rem;\
                   \border-radius:0.5rem;\
                   \color:white;\
                   \transition:all 0.5s ease"
        ]
        $ toHtml
        $ "Item "
            <> pack (show idx)
