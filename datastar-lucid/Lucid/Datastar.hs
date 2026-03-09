module Lucid.Datastar
    ( -- * DSL type
      Datastar

      -- * Signals
    , signal
    , signals
    , bind
    , computed

      -- * Events
    , on
    , onInit
    , onIntersect
    , onInterval

      -- * Display
    , dShow
    , dText
    , dAttr
    , dClass
    , dRef

      -- * Fetch
    , indicator
    , persist

      -- * Modifiers
    , Modifier (..)

      -- * Actions
    , Action
    , get
    , post
    , put
    , patch
    , delete

      -- * Expressions
    , Expr
    , act
    , raw
    , sig
    , assign
    , (&&.)
    , renderExpr

      -- * Interpreter
    , datastar
    ) where

import Control.Monad.Operational
    ( Program
    , ProgramView
    , ProgramViewT (Return, (:>>=))
    , singleton
    , view
    )
import Data.Text (Text, intercalate)
import Lucid.Base (Attribute, makeAttribute)

-- | A datastar attribute instruction
data DatastarI a where
    -- Signals
    Signal :: Text -> Text -> DatastarI ()
    Signals :: Text -> DatastarI ()
    Bind :: Text -> DatastarI ()
    Computed :: Text -> Text -> DatastarI ()
    -- Events
    On :: Text -> [Modifier] -> Expr -> DatastarI ()
    Init :: [Modifier] -> Expr -> DatastarI ()
    OnIntersect :: [Modifier] -> Expr -> DatastarI ()
    OnInterval :: [Modifier] -> Expr -> DatastarI ()
    -- Display
    Show :: Text -> DatastarI ()
    TextContent :: Text -> DatastarI ()
    Attr :: Text -> Text -> DatastarI ()
    Class :: Text -> Text -> DatastarI ()
    Ref :: Text -> DatastarI ()
    -- Fetch
    Indicator :: Text -> DatastarI ()
    Persist :: Maybe Text -> [Modifier] -> DatastarI ()

-- | Event modifier
data Modifier
    = Prevent
    | Stop
    | Once
    | Passive
    | Capture
    | Window
    | Outside
    | Debounce Text
    | Throttle Text
    | Delay Text
    | Leading
    | NoTrailing
    | NoLeading
    | Trailing
    | ViewTransition
    | Half
    | Full
    | Exit
    | Threshold Text
    | Session
    deriving (Show, Eq)

-- | Datastar DSL program
type Datastar = Program DatastarI

-- | Declare a named signal with a value
signal :: Text -> Text -> Datastar ()
signal name val = singleton (Signal name val)

-- | Patch multiple signals via JS object
signals :: Text -> Datastar ()
signals expr = singleton (Signals expr)

-- | Two-way bind to a signal
bind :: Text -> Datastar ()
bind name = singleton (Bind name)

-- | Computed signal
computed :: Text -> Text -> Datastar ()
computed name expr = singleton (Computed name expr)

-- | Attach event handler
on :: Text -> [Modifier] -> Expr -> Datastar ()
on event mods expr = singleton (On event mods expr)

-- | Initialize expression on DOM init
onInit :: Expr -> Datastar ()
onInit expr = singleton (Init [] expr)

-- | Trigger on viewport intersection
onIntersect :: [Modifier] -> Expr -> Datastar ()
onIntersect mods expr =
    singleton (OnIntersect mods expr)

-- | Trigger at intervals
onInterval :: [Modifier] -> Expr -> Datastar ()
onInterval mods expr =
    singleton (OnInterval mods expr)

-- | Conditional visibility
dShow :: Text -> Datastar ()
dShow expr = singleton (Show expr)

-- | Set text content from expression
dText :: Text -> Datastar ()
dText expr = singleton (TextContent expr)

-- | Dynamic attribute
dAttr :: Text -> Text -> Datastar ()
dAttr name expr = singleton (Attr name expr)

-- | Dynamic class
dClass :: Text -> Text -> Datastar ()
dClass name expr = singleton (Class name expr)

-- | Element reference
dRef :: Text -> Datastar ()
dRef name = singleton (Ref name)

-- | Loading indicator signal
indicator :: Text -> Datastar ()
indicator name = singleton (Indicator name)

-- | Persist signals to storage
persist :: Maybe Text -> [Modifier] -> Datastar ()
persist key mods = singleton (Persist key mods)

-- | A datastar backend action (@get, @post, etc.)
data Action = Action Text Text
    deriving (Show, Eq)

-- | @get('/url')
get :: Text -> Action
get = Action "get"

-- | @post('/url')
post :: Text -> Action
post = Action "post"

-- | @put('/url')
put :: Text -> Action
put = Action "put"

-- | @patch('/url')
patch :: Text -> Action
patch = Action "patch"

-- | @delete('/url')
delete :: Text -> Action
delete = Action "delete"

-- | Render an action to its JS expression
renderAction :: Action -> Text
renderAction (Action method url) =
    "@" <> method <> "('" <> url <> "')"

-- | A datastar JS expression
data Expr
    = -- | Backend action
      Act Action
    | -- | Raw JS expression
      Raw Text
    | -- | Signal reference ($name)
      Sig Text
    | -- | Assignment ($name = expr)
      Assign Text Expr
    | -- | Logical AND (expr && expr)
      And Expr Expr
    deriving (Show, Eq)

-- | Backend action expression
act :: Action -> Expr
act = Act

-- | Raw JS expression
raw :: Text -> Expr
raw = Raw

-- | Signal reference ($name)
sig :: Text -> Expr
sig = Sig

-- | Assignment ($name = expr)
assign :: Text -> Expr -> Expr
assign = Assign

-- | Logical AND of two expressions
(&&.) :: Expr -> Expr -> Expr
(&&.) = And

infixr 3 &&.

-- | Render an expression to JS text
renderExpr :: Expr -> Text
renderExpr (Act a) = renderAction a
renderExpr (Raw t) = t
renderExpr (Sig name) = "$" <> name
renderExpr (Assign name e) =
    "$" <> name <> " = " <> renderExpr e
renderExpr (And l r) =
    renderExpr l <> " && " <> renderExpr r

{- | Interpret a datastar program into
Lucid attributes
-}
datastar :: Datastar () -> [Attribute]
datastar = go . view
  where
    go :: ProgramView DatastarI () -> [Attribute]
    go (Return ()) = []
    go (Signal name val :>>= k) =
        attr' ("data-signals:" <> name) val k
    go (Signals expr :>>= k) =
        attr' "data-signals" expr k
    go (Bind name :>>= k) =
        attr' ("data-bind:" <> name) "" k
    go (Computed name expr :>>= k) =
        attr' ("data-computed:" <> name) expr k
    go (On event mods expr :>>= k) =
        attr'
            ("data-on:" <> event <> renderMods mods)
            (renderExpr expr)
            k
    go (Init mods expr :>>= k) =
        attr'
            ("data-init" <> renderMods mods)
            (renderExpr expr)
            k
    go (OnIntersect mods expr :>>= k) =
        attr'
            ( "data-on-intersect"
                <> renderMods mods
            )
            (renderExpr expr)
            k
    go (OnInterval mods expr :>>= k) =
        attr'
            ( "data-on-interval"
                <> renderMods mods
            )
            (renderExpr expr)
            k
    go (Show expr :>>= k) =
        attr' "data-show" expr k
    go (TextContent expr :>>= k) =
        attr' "data-text" expr k
    go (Attr name expr :>>= k) =
        attr' ("data-attr:" <> name) expr k
    go (Class name expr :>>= k) =
        attr' ("data-class:" <> name) expr k
    go (Ref name :>>= k) =
        attr' "data-ref" name k
    go (Indicator name :>>= k) =
        attr' ("data-indicator:" <> name) "" k
    go (Persist key mods :>>= k) =
        attr'
            ( "data-persist"
                <> maybe "" (":" <>) key
                <> renderMods mods
            )
            ""
            k

    attr' name val k =
        makeAttribute name val : go (view (k ()))

renderMods :: [Modifier] -> Text
renderMods [] = ""
renderMods mods =
    "__" <> intercalate "__" (fmap renderMod mods)

renderMod :: Modifier -> Text
renderMod Prevent = "prevent"
renderMod Stop = "stop"
renderMod Once = "once"
renderMod Passive = "passive"
renderMod Capture = "capture"
renderMod Window = "window"
renderMod Outside = "outside"
renderMod (Debounce t) = "debounce." <> t
renderMod (Throttle t) = "throttle." <> t
renderMod (Delay t) = "delay." <> t
renderMod Leading = "leading"
renderMod NoTrailing = "notrailing"
renderMod NoLeading = "noleading"
renderMod Trailing = "trailing"
renderMod ViewTransition = "viewtransition"
renderMod Half = "half"
renderMod Full = "full"
renderMod Exit = "exit"
renderMod (Threshold t) = "threshold." <> t
renderMod Session = "session"
