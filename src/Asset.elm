module Asset exposing (Image, notFound, src)

{-| Utilities for linking to asset paths
-}

import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type Image
    = Image String



-- IMAGES


notFound : Image
notFound =
    image "not_found.jpg"


image : String -> Image
image filename =
    Image ("/assets/images/" ++ filename)



-- USING ASSETS


src : Image -> Attribute msg
src (Image url) =
    Attr.src url
