module Ui exposing (bottomBanner, buttonLink, heading, paragraph, textbox)

import Html exposing (Html, a, div, h1, img, p)
import Html.Attributes exposing (class)


heading attrs children =
    h1 (class "mv0 f2 f1-ns lh-title f-wildberry" :: attrs) children


bottomBanner attrs children =
    div [ class "absolute bottom-0 left-0 w-100" ]
        [ div [ class "mw7 center" ] children
        ]


paragraph attrs children =
    p (class "mv0 f5 lh-copy" :: attrs) children


textbox attrs children =
    div (class "measure" :: attrs) children


buttonLink attrs children =
    a (class "db mw5 center pa3 button-link b bg-blue br2 near-white hover-bg-light-blue hover-near-black" :: attrs) children
