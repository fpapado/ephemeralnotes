module Page exposing (FocusState(..), Page(..), view)

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Html exposing (Html, a, button, div, footer, h1, header, i, img, li, main_, nav, p, span, text, ul)
import Html.Attributes as HA exposing (class, classList, href, id, style, tabindex)
import Html.Events exposing (onBlur, onClick)
import Route exposing (Route)
import Svg.Feather as Feather
import Ui


{-| Determines which navbar link (if any) will be rendered as active.

Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.

-}
type Page
    = Other
    | Home
    | Map
    | Data
    | Settings
    | About


type FocusState
    = NotYetFocused
    | Focusing
    | FocusOnMain
    | FocusPastMain
    | FocusErr


{-| Take a page's Html and frames it with a header and footer.

The caller provides the content, which must use the provided "main" element, so that we can
focus it on transition.
The "main" element handles the state of being focused or not, to toggle tabindex dynamically.

-}
view : { activePage : Page, focusState : FocusState, onBlurredMain : msg, onPressedBack : msg, toOutMsg : innerMsg -> msg } -> { title : String, content : Html innerMsg } -> Document msg
view { activePage, focusState, onBlurredMain, onPressedBack, toOutMsg } { title, content } =
    let
        -- The main element that the caller must render
        -- We must dynamically set the tabindex, to avoid a critical but where it captures/steals focus
        mainAttrs =
            case focusState of
                -- When focusing, set tabindex to -1
                Focusing ->
                    [ id "main"
                    , tabindex -1
                    ]

                -- When the user tabs past, then the state should be set to FocusPastMain
                FocusOnMain ->
                    [ id "main"
                    , tabindex -1
                    , onBlur onBlurredMain
                    ]

                -- In other cases, no need for focus attributes
                _ ->
                    [ id "main"
                    ]

        viewMain =
            main_ mainAttrs
    in
    { title = title ++ " | Ephemeral"
    , body =
        [ viewShell
            [ viewHeader activePage onPressedBack
            , viewMain [ Html.map toOutMsg content ]
            ]
        ]
    }


viewShell children =
    div [ class "min-vh-100 bg-color-bg color-text f-phantomsans lh-copy elm-root" ] children


viewHeader : Page -> msg -> Html msg
viewHeader activePage onPressedBack =
    header [ class "navigation-header bg-color-lighter color-text-faint bb lh-title" ]
        [ skipLink
        , nav [ class "navigation-container" ]
            [ div [ class "navigation-title-about flex items-center mw7" ]
                [ div [ class "navigation-back-button" ]
                    [ button
                        [ class "button-reset lh-solid v-mid color-text focus-shadow pointer"
                        , onClick onPressedBack
                        ]
                        [ Feather.arrowLeft (Feather.Content { label = "Previous page" })
                        ]
                    ]
                , div [ class "w-100 navigation-title" ]
                    [ a
                        [ Route.href Route.Home
                        , class "f3 fw7 link color-accent tc navigation-home"
                        ]
                        [ text "Ephemeral" ]
                    ]
                , div [ class "navigation-about" ]
                    [ a
                        [ Route.href Route.About
                        , classList
                            [ ( "dib link lh-solid v-mid", True )
                            , ( "color-text", not (isActive activePage Route.About) )
                            , ( "color-accent", isActive activePage Route.About )
                            ]
                        ]
                        [ Feather.info (Feather.Content { label = "Info" })
                        ]
                    ]
                ]
            , viewNavBar activePage
            ]
        ]


viewNavBar : Page -> Html msg
viewNavBar page =
    let
        navLink route displayText icon =
            let
                isActivePage =
                    isActive page route

                ariaCurrent =
                    if isActivePage then
                        [ HA.attribute "aria-current" "page" ]

                    else
                        []
            in
            a
                ([ Route.href route
                 , classList
                    [ ( "db f5 f4-ns link", True )
                    , ( "color-text", not isActivePage )
                    , ( "color-accent", isActivePage )
                    ]
                 ]
                    ++ ariaCurrent
                )
                [ icon Feather.Decorative
                , div [] [ text displayText ]
                ]
    in
    div [ class "navigation-bar bg-color-lighter lh-solid" ]
        [ div [ class "navigation-bar-flex" ]
            [ navLink Route.Home "Entries" Feather.clipboard
            , navLink Route.Map "Map" Feather.map
            , navLink Route.Data "Data" Feather.archive
            , navLink Route.Settings "Settings" Feather.gear
            ]
        ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Home, Route.Home ) ->
            True

        ( Map, Route.Map ) ->
            True

        ( Data, Route.Data ) ->
            True

        ( Settings, Route.Settings ) ->
            True

        ( About, Route.About ) ->
            True

        _ ->
            False


skipLink =
    a
        [ href "#main"
        , class "pa3 tc near-white bg-blue skip-link"
        ]
        [ text "Skip to content." ]
