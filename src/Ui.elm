module Ui exposing (buttonLink, calloutContainer, heading, paragraph, prompt, textbox)

import Html exposing (Html, a, button, div, h1, img, p)
import Html.Attributes exposing (class)


heading level attrs children =
    let
        tagName =
            "h" ++ String.fromInt (clamp 1 6 level)
    in
    Html.node tagName (class "mv0 f2 f1-ns lh-title f-wildberry" :: attrs) children


styledButton attrs children =
    button (class "db mw5 center pa3 button-link b bg-blue br2 near-white hover-bg-light-blue hover-near-black" :: attrs) children


calloutContainer attrs children =
    div (class "fixed bottom-0 left-0 w-100 br1" :: attrs)
        [ div [ class "mw7 center" ] children
        ]


prompt attrs children =
    div (class "pa3 flex justify-center items-center bg-white near-black shadow-1 animated fadeInUp" :: attrs) children


paragraph attrs children =
    p (class "mv0 f5 lh-copy" :: attrs) children


textbox attrs children =
    div (class "measure" :: attrs) children


buttonLink attrs children =
    a (class "db mw5 center pa3 button-link b bg-blue br2 near-white hover-bg-light-blue hover-near-black" :: attrs) children
