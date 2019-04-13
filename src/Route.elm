module Route exposing (Route(..), fromUrl, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), Parser, oneOf, s, string)



-- ROUTING


type Route
    = Home
    | Map
    | Data


parser : Parser (Route -> a) a
parser =
    oneOf
        [ UrlParser.map Map (s "map")
        , UrlParser.map Data (s "data")
        , UrlParser.map Home UrlParser.top
        ]



-- PUBLIC HELPERS


{-| Construct a link target for a specific route
-}
href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


{-| Wrapper around Nav.replace for redirects
-}
replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


{-| Get a route from a Url
-}
fromUrl : Url -> Maybe Route
fromUrl url =
    UrlParser.parse parser url



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    []

                Map ->
                    [ "map" ]

                Data ->
                    [ "data" ]
    in
    "/" ++ String.join "/" pieces
