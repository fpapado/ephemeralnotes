module String.Transforms exposing (fromValue)

{-| Utilities for transforming various types to a String
-}

import Json.Encode as JE exposing (Value)


{-| Convert a Json Value to a JSON String.
-}
fromValue : Value -> String
fromValue value =
    JE.encode 0 value
