module Svg.Feather exposing
    ( Purpose(..)
    , alertCircle
    , archive
    , checkCircle
    , clipboard
    , download
    , gear
    , info
    , map
    , svgFeatherIcon
    , upload
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


gear : Purpose -> Html msg
gear =
    svgFeatherIcon
        [ Svg.circle [ cx "12", cy "12", r "3" ] []
        , Svg.path [ d "M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" ] []
        ]


checkCircle : Purpose -> Html msg
checkCircle =
    svgFeatherIcon
        [ Svg.path [ d "M22 11.08V12a10 10 0 1 1-5.93-9.14" ] []
        , Svg.polyline [ points "22 4 12 14.01 9 11.01" ] []
        ]


alertCircle : Purpose -> Html msg
alertCircle =
    svgFeatherIcon
        [ Svg.circle [ cx "12", cy "12", r "10" ] []
        , Svg.line [ x1 "12", y1 "8", x2 "12", y2 "12" ] []
        , Svg.line [ x1 "12", y1 "16", x2 "12", y2 "16" ] []
        ]


download : Purpose -> Html msg
download =
    svgFeatherIcon
        [ Svg.path [ d "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" ] []
        , Svg.polyline [ points "7 10 12 15 17 10" ] []
        , Svg.line [ x1 "12", y1 "15", x2 "12", y2 "3" ] []
        ]


info : Purpose -> Html msg
info =
    svgFeatherIcon
        [ Svg.circle [ cx "12", cy "12", r "10" ] []
        , Svg.line [ x1 "12", y1 "16", x2 "12", y2 "12" ] []
        , Svg.line [ x1 "12", y1 "8", x2 "12", y2 "8" ] []
        ]


upload : Purpose -> Html msg
upload =
    svgFeatherIcon
        [ Svg.path [ d "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" ] []
        , Svg.polyline [ points "17 8 12 3 7 8" ] []
        , Svg.line [ x1 "12", y1 "3", x2 "12", y2 "15" ] []
        ]
