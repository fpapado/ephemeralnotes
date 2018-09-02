module Page exposing (Page(..), view, viewErrors)

import Browser exposing (Document)
import Html exposing (Html, a, button, div, footer, h1, header, i, img, li, main_, nav, p, span, text, ul)
import Html.Attributes exposing (class, classList, href, id, style, tabindex)
import Html.Events exposing (onClick)
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


{-| Take a page's Html and frames it with a header and footer.

The caller provides the current user, so we can display in either
"signed in" (rendering username) or "signed out" mode.

isLoading is for determining whether we should show a loading spinner
in the header. (This comes up during slow page transitions.)

-}
view : Page -> { title : String, content : Html msg } -> Document msg
view activePage { title, content } =
    { title = title ++ " | Ephemeral"
    , body =
        [ viewShell
            [ viewHeader activePage
            , main_
                [ id "main"
                , class "flex-auto"
                , tabindex -1
                ]
                [ container []
                    [ content
                    ]
                ]
            , viewFooter
            , viewInstallBanner
            ]
        ]
    }


viewInstallBanner : Html msg
viewInstallBanner =
    Ui.bottomBanner []
        [ Html.node "install-banner" [] []
        ]


viewShell children =
    div [ class "min-vh-100 flex flex-column sans-serif bg-washed-blue near-black" ] children


{-| Might have to pull this out of the layout in the future
-}
container attrs children =
    div ([ class "pa3 mw8 center" ] ++ attrs) children


viewHeader : Page -> Html msg
viewHeader activePage =
    header [ class "pv2 navy bg-white shadow-1" ]
        [ skipLink
        , nav [ class "tc" ] [ a [ Route.href Route.Home, class "f3 fw7 link navy tc ttu f-wildberry" ] [ text "Ephemeral" ] ]
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


{-| Render dismissable errors. We use this all over the place!
-}
viewErrors : msg -> List String -> Html msg
viewErrors dismissErrors errors =
    if List.isEmpty errors then
        Html.text ""

    else
        div
            [ class "error-messages"
            , style "position" "fixed"
            , style "top" "0"
            , style "background" "rgb(250, 250, 250)"
            , style "padding" "20px"
            , style "border" "1px solid"
            ]
        <|
            List.map (\error -> p [] [ text error ]) errors
                ++ [ button [ onClick dismissErrors ] [ text "Ok" ] ]


skipLink =
    a [ href "#main", class "pa3 tc near-white bg-blue skip-link" ] [ text "skip to content" ]
