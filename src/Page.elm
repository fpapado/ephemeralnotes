module Page exposing (FocusState(..), Page(..), view)

import Browser exposing (Document)
import Html exposing (Html, a, button, div, footer, h1, header, i, img, li, main_, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, href, id, style, tabindex)
import Html.Events exposing (onBlur, onClick)
import Route exposing (Route)
import Ui


{-| Determines which navbar link (if any) will be rendered as active.

Note that we don't enumerate every page here, because the navbar doesn't
have links for every page. Anything that's not part of the navbar falls
under Other.

-}
type Page
    = Other
    | Home


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
        , nav [ class "tc" ] [ a [ Route.href Route.Home, class "f3 fw7 link navy tc" ] [ text "Ephemeral" ] ]
        ]


viewFooter : Html msg
viewFooter =
    footer []
        [ container [ class "tc" ]
            [ span [] [ text "Made by Fotis Papadogeorgopoulos" ]
            ]
        ]


navbarLink : Page -> Route -> List (Html msg) -> Html msg
navbarLink page route linkContent =
    li [ classList [ ( "nav-item", True ), ( "active", isActive page route ) ] ]
        [ a [ class "nav-link", Route.href route ] linkContent ]


isActive : Page -> Route -> Bool
isActive page route =
    case ( page, route ) of
        ( Home, Route.Home ) ->
            True

        _ ->
            False


skipLink =
    a [ href "#main", class "pa3 tc near-white bg-blue skip-link" ] [ text "skip to content" ]
