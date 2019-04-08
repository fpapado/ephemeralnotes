module Svg.NoData exposing (view)

import Html exposing (div, p)
import Html.Attributes as HA
import Svg exposing (..)
import Svg.Attributes exposing (..)


view ( defaultText1, defaultText2 ) ( text1, text2 ) attrs =
    let
        t1 =
            if text1 == "" then
                defaultText1

            else
                text1

        t2 =
            if text2 == "" then
                defaultText2

            else
                text2
    in
    svg
        ([ viewBox "0 0 820.16 780.81"
         , HA.attribute "focusable" "false"
         , HA.attribute "role" "img"
         , HA.attribute "aria-label" "A clipboard with sparkles"
         ]
            ++ attrs
        )
        [ defs []
            [ linearGradient
                [ id "a"
                , x1 "539.63"
                , x2 "539.63"
                , y1 "734.6"
                , y2 "151.19"
                , gradientTransform "translate(-3.62 1.57)"
                , gradientUnits "userSpaceOnUse"
                ]
                [ stop [ offset "0", stopColor "gray", stopOpacity ".25" ] [], stop [ offset ".54", stopColor "gray", stopOpacity ".12" ] [], stop [ offset "1", stopColor "gray", stopOpacity ".1" ] [] ]
            , linearGradient [ id "b", x1 "540.17", x2 "540.17", y1 "180.2", y2 "130.75", gradientTransform "translate(-63.92 7.85)" ] []
            , linearGradient [ id "c", x1 "540.17", x2 "540.17", y1 "140.86", y2 "82.43", gradientTransform "rotate(-12.11 545.066 460.6507)" ] []
            , linearGradient [ id "d", x1 "476.4", x2 "476.4", y1 "710.53", y2 "127.12" ] []
            , linearGradient [ id "e", x1 "476.94", x2 "476.94", y1 "156.13", y2 "106.68" ] []
            , linearGradient [ id "f", x1 "666.86", x2 "666.86", y1 "176.39", y2 "117.95" ] []
            ]
        , Svg.path [ fill "#e0e0e0", d "M69.12 135.4897l427.2948-91.682 126.675 590.3829-427.2949 91.682z" ] []
        , Svg.path [ fill "url(#a)", d "M324.89 152.76h422.25v583.41H324.89z", opacity ".5", transform "rotate(-12.11 160.0302 1309.7967)" ] []
        , Svg.path [ fill "#fafafa", d "M84.6385 146.9934l402.3427-86.3282 119.689 557.824-402.3428 86.3282z" ] []
        , Svg.path [ fill "url(#b)", d "M374.18 138.6h204.14v49.45H374.18z", transform "rotate(-12.11 100.2807 1028.7068)" ] []
        , Svg.path [ fill "url(#c)", d "M460.93 91.9c-15.41 3.31-25.16 18.78-21.77 34.55s18.62 25.89 34 22.58 25.16-18.78 21.77-34.55-18.59-25.89-34-22.58zm9.67 45.1a16.86 16.86 0 1 1 12.56-20 16.66 16.66 0 0 1-12.56 20z", transform "translate(-189.92 -59.59)" ] []
        , Svg.path [ fill "#6c63ff", d "M183.007 98.4219L378.4 56.4976l9.9166 46.218L192.9238 144.64z" ] []
        , Svg.path [ fill "#6c63ff", d "M271.01 32.31a27.93 27.93 0 1 0 33.17 21.45 27.93 27.93 0 0 0-33.17-21.45zm9.24 43.1a16.12 16.12 0 1 1 12.38-19.14 16.12 16.12 0 0 1-12.38 19.14z" ] []
        , Svg.path [ fill "#e0e0e0", d "M257.89 116.91h437.02v603.82H257.89z" ] []
        , Svg.path [ fill "url(#d)", d "M265.28 127.12h422.25v583.41H265.28z", opacity ".5" ] []
        , Svg.path [ fill "#fff", d "M270.65 131.42h411.5v570.52h-411.5z" ] []
        , Svg.path [ fill "url(#e)", d "M374.87 106.68h204.14v49.45H374.87z" ] []
        , Svg.path [ fill "url(#f)", d "M666.86 118c-15.76 0-28.54 13.08-28.54 29.22s12.78 29.22 28.54 29.22 28.54-13.08 28.54-29.22S682.62 118 666.86 118zm0 46.08a16.86 16.86 0 1 1 16.46-16.86A16.66 16.66 0 0 1 666.86 164z", transform "translate(-189.92 -59.59)" ] []
        , Svg.path [ fill "#6c63ff", d "M377.02 104.56h199.84v47.27H377.02z" ] []
        , Svg.path [ fill "#6c63ff", d "M476.94 58.41a27.93 27.93 0 1 0 27.93 27.93 27.93 27.93 0 0 0-27.93-27.93zm0 44.05a16.12 16.12 0 1 1 16.14-16.16 16.12 16.12 0 0 1-16.14 16.11z" ] []
        , g [ fill "#47e6b1", opacity ".5" ] [ Svg.path [ d "M15.27 737.05h3.76v21.33h-3.76z" ] [], Svg.path [ d "M27.82 745.84v3.76H6.49v-3.76z" ] [] ]
        , g [ fill "#47e6b1", opacity ".5" ] [ Svg.path [ d "M451.49 0h3.76v21.33h-3.76z" ] [], Svg.path [ d "M464.04 8.78v3.76h-21.33V8.78z" ] [] ]
        , Svg.path [ fill "#4d8af0", d "M771.08 772.56a4.61 4.61 0 0 1-2.57-5.57 2.22 2.22 0 0 0 .1-.51 2.31 2.31 0 0 0-4.15-1.53 2.22 2.22 0 0 0-.26.45 4.61 4.61 0 0 1-5.57 2.57 2.22 2.22 0 0 0-.51-.1 2.31 2.31 0 0 0-1.53 4.15 2.22 2.22 0 0 0 .45.26 4.61 4.61 0 0 1 2.57 5.57 2.22 2.22 0 0 0-.1.51 2.31 2.31 0 0 0 4.15 1.53 2.22 2.22 0 0 0 .26-.45 4.61 4.61 0 0 1 5.57-2.57 2.22 2.22 0 0 0 .51.1 2.31 2.31 0 0 0 1.53-4.15 2.22 2.22 0 0 0-.45-.26z", opacity ".5" ] []
        , Svg.path [ fill "#fdd835", d "M136.67 567.5a4.61 4.61 0 0 1-2.57-5.57 2.22 2.22 0 0 0 .1-.51 2.31 2.31 0 0 0-4.15-1.53 2.22 2.22 0 0 0-.26.45 4.61 4.61 0 0 1-5.57 2.57 2.22 2.22 0 0 0-.51-.1 2.31 2.31 0 0 0-1.53 4.15 2.22 2.22 0 0 0 .45.26 4.61 4.61 0 0 1 2.57 5.57 2.22 2.22 0 0 0-.1.51 2.31 2.31 0 0 0 4.15 1.53 2.22 2.22 0 0 0 .26-.45 4.61 4.61 0 0 1 5.57-2.57 2.22 2.22 0 0 0 .51.1 2.31 2.31 0 0 0 1.53-4.15 2.22 2.22 0 0 0-.45-.26zM665.08 68.18a4.61 4.61 0 0 1-2.57-5.57 2.22 2.22 0 0 0 .1-.51 2.31 2.31 0 0 0-4.15-1.53 2.22 2.22 0 0 0-.26.45 4.61 4.61 0 0 1-5.57 2.57 2.22 2.22 0 0 0-.51-.1 2.31 2.31 0 0 0-1.53 4.15 2.22 2.22 0 0 0 .45.26 4.61 4.61 0 0 1 2.57 5.57 2.22 2.22 0 0 0-.1.51 2.31 2.31 0 0 0 4.15 1.53 2.22 2.22 0 0 0 .26-.45 4.61 4.61 0 0 1 5.57-2.57 2.22 2.22 0 0 0 .51.1 2.31 2.31 0 0 0 1.53-4.15 2.22 2.22 0 0 0-.45-.26z", opacity ".5" ] []
        , circle [ cx "812.64", cy "314.47", r "7.53", fill "#f55f44", opacity ".5" ] []
        , circle [ cx "230.73", cy "746.65", r "7.53", fill "#f55f44", opacity ".5" ] []
        , circle [ cx "735.31", cy "477.23", r "7.53", fill "#f55f44", opacity ".5" ] []
        , circle [ cx "87.14", cy "96.35", r "7.53", fill "#4d8af0", opacity ".5" ] []
        , circle [ cx "7.53", cy "301.76", r "7.53", fill "#47e6b1", opacity ".5" ] []
        , foreignObject [ x "300", y "220", height "400", width "360" ]
            [ div [ class "f2 fw4 near-black lh-title tl" ]
                [ p [ class "mt0 mb3" ] [ text t1 ]
                , p [ class "mv0" ] [ text t2 ]
                ]
            ]
        ]
