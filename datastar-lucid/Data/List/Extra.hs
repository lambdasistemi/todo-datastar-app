module Data.List.Extra
    ( -- * DSL type
      ListM

      -- * Constructors
    , item
    , items
    , when'

      -- * Interpreter
    , collect
    ) where

import Control.Monad.Operational
    ( Program
    , ProgramView
    , ProgramViewT (Return, (:>>=))
    , singleton
    , view
    )

-- | A list-building instruction
data ListI a b where
    Item :: a -> ListI a ()
    Items :: [a] -> ListI a ()

-- | A list-building program
type ListM a = Program (ListI a)

-- | Append a single element
item :: a -> ListM a ()
item = singleton . Item

-- | Append multiple elements
items :: [a] -> ListM a ()
items = singleton . Items

-- | Conditionally append
when' :: Bool -> ListM a () -> ListM a ()
when' True m = m
when' False _ = pure ()

-- | Collect the list
collect :: ListM a () -> [a]
collect = go . view
  where
    go :: ProgramView (ListI a) () -> [a]
    go (Return ()) = []
    go (Item x :>>= k) = x : go (view (k ()))
    go (Items xs :>>= k) = xs <> go (view (k ()))
