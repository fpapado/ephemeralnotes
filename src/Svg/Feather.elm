module Svg.Feather exposing
    ( Purpose(..)
    , archive
    , clipboard
    , map
    )

import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)


type Purpose
    = Decorative
    | Content { label : String }


svgFeatherIcon : List (Svg msg) -> Purpose -> Html msg
svgFeatherIcon children purpose =
    let
        accessibleAttributes =
            case purpose of
                -- If Decorative, hide from Assistive Technologies
                Decorative ->
                    [ HA.attribute "aria-hidden" "true" ]

                -- If Content, set the aria-label, and treat it as img (content)
                -- TODO: Consider label with title and aria-labelledby
                Content { label } ->
                    [ HA.attribute "aria-label" label
                    , HA.attribute "role" "img"
                    ]
    in
    svg
        ([ fill "none"
         , stroke "currentColor"
         , strokeLinecap "round"
         , strokeLinejoin "round"
         , strokeWidth "2"
         , viewBox "0 0 24 24"
         , height "20"
         , width "20"
         , HA.attribute "focusable" "false"
         ]
            ++ accessibleAttributes
        )
        children


archive : Purpose -> Html msg
archive =
    svgFeatherIcon
        [ Svg.polyline [ points "21 8 21 21 3 21 3 8" ] []
        , Svg.rect [ Svg.Attributes.x "1", y "3", width "22", height "5" ] []
        , Svg.line [ x1 "10", y1 "12", x2 "14", y2 "12" ] []
        ]


clipboard : Purpose -> Html msg
clipboard =
    svgFeatherIcon
        [ Svg.path [ d "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" ] []
        , Svg.rect [ Svg.Attributes.x "8", y "2", width "8", height "4", rx "1", ry "1" ] []
        ]


map : Purpose -> Html msg
map =
    svgFeatherIcon
        [ Svg.polygon [ points "1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6" ] []
        , Svg.line [ x1 "8", y1 "2", x2 "8", y2 "18" ] []
        , Svg.line [ x1 "16", y1 "6", x2 "16", y2 "22" ] []
        ]
