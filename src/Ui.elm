module Ui exposing
    ( buttonLink
    , calloutContainer
    , centeredContainer
    , centeredContainerWide
    , checkbox
    , heading
    , notificationRegion
    , paragraph
    , paragraphSmall
    , prompt
    , styledButton
    , styledButtonBlue
    , subHeading
    , subSubHeading
    , textbox
    )

import Html as H exposing (..)
import Html.Attributes as HA exposing (..)


heading level attrs children =
    let
        tagName =
            "h" ++ String.fromInt (clamp 1 6 level)
    in
    H.node tagName (class "mv0 f2 f1-ns lh-title fw7" :: attrs) children


subHeading level attrs children =
    let
        tagName =
            "h" ++ String.fromInt (clamp 1 6 level)
    in
    H.node tagName (class "mv0 f3 f2-ns lh-title fw7" :: attrs) children


subSubHeading level attrs children =
    let
        tagName =
            "h" ++ String.fromInt (clamp 1 6 level)
    in
    H.node tagName (class "mv0 f4 f3-ns lh-title fw7" :: attrs) children


centeredContainer attrs children =
    div (class "mw7 center" :: attrs) children


centeredContainerWide attrs children =
    div (class "mw9 center" :: attrs) children


styledButton attrs children =
    button (class "pv2 ph3 button-reset focus-shadow br2 f4 fw5" :: attrs) children


styledButtonBlue isReadOnly attrs children =
    let
        cls =
            if isReadOnly then
                "bg-light-blue near-black"

            else
                "bg-blue near-white hover-bg-light-blue hover-near-black"
    in
    styledButton (class cls :: attrs) children


calloutContainer attrs children =
    div (class "fixed bottom-0 left-0 w-100 br1" :: attrs)
        [ div [ class "mw6 center" ] children
        ]


{-| A region that explicitly announces its content to screen readers.
Use it in cases where you show notification popups visually, and want a
comparable experience for screen reader users.

    Bear in mind that screen readers announce changes already, so you shouldn't
    need this for most of the content on a page!

-}
notificationRegion attrs children =
    div ([ HA.attribute "role" "status", HA.attribute "aria-live" "polite" ] ++ attrs) children


prompt attrs children =
    div (class "pa3 flex flex-wrap justify-around items-center bg-color-bg color-text shadow-1 animated fadeInUp" :: attrs) children


paragraph attrs children =
    p (class "mv0 f-paragraph f4-ns lh-copy measure" :: attrs) children


paragraphSmall attrs children =
    p (class "mv0 f5 lh-copy measure" :: attrs) children


textbox attrs children =
    div (class "measure" :: attrs) children


buttonLink attrs children =
    a (class "db mw5 center pa3 button-link fw5 bg-blue br2 near-white hover-bg-light-blue hover-near-black focus-shadow" :: attrs) children


{-| A progressively-enhanced, larger heckbox
-}
checkbox : { id : String, name : String, isReadOnly : Bool } -> List (H.Attribute msg) -> String -> Html msg
checkbox config attrs labelText =
    let
        modifierCls =
            if config.isReadOnly then
                "enhanced-checkbox--readonly"

            else
                ""
    in
    div [ class "enhanced-checkbox-container f-paragraph f4-ns lh-copy v-mid fw6", class modifierCls ]
        [ input
            ([ id config.id, name config.name, type_ "checkbox", class "enhanced-checkbox-input" ] ++ attrs)
            []
        , label
            [ for config.id, class "enhanced-checkbox-label" ]
            [ text labelText ]
        ]
