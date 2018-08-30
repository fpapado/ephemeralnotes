module Ui exposing (buttonLink, heading)

import Html exposing (Html, a, div, h1, img, p)
import Html.Attributes exposing (class)


heading attrs children =
    h1 (class "f2 f1-ns lh-title f-wildberry" :: attrs) children


buttonLink attrs children =
    a (class "db mw5 center pa3 button-link b bg-blue br2 near-white hover-bg-light-blue hover-near-black" :: attrs) children
