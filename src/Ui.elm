module Ui exposing (buttonLink, calloutContainer, heading, paragraph, prompt, styledButton, styledButtonBlue, textbox)

import Html exposing (Html, a, button, div, h1, img, p)
import Html.Attributes exposing (class)


heading level attrs children =
    let
        tagName =
            "h" ++ String.fromInt (clamp 1 6 level)
    in
    Html.node tagName (class "mv0 f2 f1-ns lh-title" :: attrs) children


styledButton attrs children =
    button (class "pv2 ph3 button-reset focus-shadow br2 b" :: attrs) children


styledButtonBlue attrs children =
    styledButton (class "bg-blue near-white hover-bg-light-blue hover-near-black" :: attrs) children


calloutContainer attrs children =
    div (class "fixed bottom-0 left-0 w-100 br1" :: attrs)
        [ div [ class "mw6 center" ] children
        ]


prompt attrs children =
    div (class "pa3 flex justify-around items-center bg-white near-black shadow-1 animated fadeInUp" :: attrs) children


paragraph attrs children =
    p (class "mv0 f5 lh-copy" :: attrs) children


textbox attrs children =
    div (class "measure" :: attrs) children


buttonLink attrs children =
    a (class "db mw5 center pa3 button-link b bg-blue br2 near-white hover-bg-light-blue hover-near-black focus-shadow" :: attrs) children
