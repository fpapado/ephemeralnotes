module Page exposing (FocusState(..), Page(..), view)

import Browser exposing (Document)
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
view : { activePage : Page, focusState : FocusState, onBlurredMain : msg, toOutMsg : innerMsg -> msg } -> { title : String, content : Html innerMsg } -> Document msg
view { activePage, focusState, onBlurredMain, toOutMsg } { title, content } =
    let
        -- The main element that the caller must render
        -- We must dynamically set the tabindex, to avoid a critical but where it captures/steals focus
        mainAttrs =
            case focusState of
                -- When focusing, set tabindex to -1
                Focusing ->
                    [ id "main"
                    , class "pa3 flex flex-column flex-auto"
                    , tabindex -1
                    ]

                -- When the user tabs past, then the state should be set to FocusPastMain
                FocusOnMain ->
                    [ id "main"
                    , class "pa3 flex flex-column flex-auto"
                    , tabindex -1
                    , onBlur onBlurredMain
                    ]

                -- In other cases, no need for focus attributes
                _ ->
                    [ id "main"
                    , class "pa3 flex flex-column flex-auto"
                    ]

        viewMain =
            main_ mainAttrs
    in
    { title = title ++ " | Ephemeral"
    , body =
        [ viewShell
            [ viewHeader activePage
            , viewMain [ Html.map toOutMsg content ]
            , viewFooter
            ]
        ]
    }


viewShell children =
    div [ class "min-vh-100 flex flex-column bg-washed-blue near-black f-phantomsans" ] children


{-| Might have to pull this out of the layout in the future
-}
container attrs children =
    div ([ class "pa3 flex-auto" ] ++ attrs) children


viewHeader : Page -> Html msg
viewHeader activePage =
    header [ class "pv2 navy bg-white shadow-1" ]
        [ skipLink
        , nav [ class "navigation-container" ]
            [ a
                [ Route.href Route.Home
                , class "f3 fw7 link navy tc navigation-home"
                ]
                [ text "Ephemeral" ]
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
                    , ( "near-black", not isActivePage )
                    , ( "blue", isActivePage )
                    ]
                 ]
                    ++ ariaCurrent
                )
                [ icon Feather.Decorative
                , div [] [ text displayText ]
                ]
    in
    div [ class "navigation-bar w-100 bg-white" ]
        [ div [ class "navigation-bar-flex" ]
            [ navLink Route.Home "Entries" Feather.clipboard
            , navLink Route.Map "Map" Feather.map
            , navLink Route.Data "Data" Feather.archive
            ]
        ]


viewFooter : Html msg
viewFooter =
    -- The footer sets a safe area for the fixed bottom
    footer [ class "footer" ]
        [ container [ class "tc" ]
            [ span [] [ text "Made by Fotis Papadogeorgopoulos" ]
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

        _ ->
            False


skipLink =
    a
        [ href "#main"
        , class "pa3 tc near-white bg-blue skip-link"
        ]
        [ text "skip to content" ]
