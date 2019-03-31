module Asset exposing (Image, noData, toAttr)

{-| Utilities for linking to asset paths
-}

import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type Image
    = Image ( String, String )



-- IMAGES


noData : Image
noData =
    image ( "no_data_qbuo.svg", "An empty clipboard with sparkles." )


image : ( String, String ) -> Image
image ( filename, alt ) =
    Image ( "/assets/images/" ++ filename, alt )



-- USING ASSETS


toAttr : Image -> List (Attribute msg)
toAttr (Image ( url, alt )) =
    [ Attr.src url
    , Attr.alt alt
    ]
