module Asset exposing (Image, toAttr)

{-| Utilities for linking to asset paths
-}

import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type Image
    = Image ( String, String )



-- IMAGES


image : ( String, String ) -> Image
image ( filename, alt ) =
    Image ( "/assets/images/" ++ filename, alt )



-- USING ASSETS


toAttr : Image -> List (Attribute msg)
toAttr (Image ( url, alt )) =
    [ Attr.src url
    , Attr.alt alt
    ]
