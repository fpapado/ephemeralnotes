module Page.NotFound exposing (view)

import Html exposing (Html, a, div, h1, img, p, text)
import Html.Attributes exposing (alt, class, id, src, tabindex)
import Route exposing (Route)



-- VIEW


view : { title : String, content : Html msg }
view =
    { title = "Page Not Found"
    , content =
        div [ id "content", class "center", tabindex -1 ]
            [ div
                [ class "tc measure center vs4" ]
                [ h1 [ class "mv4 f2 f1-ns lh-title f-wildberry" ] [ text "Not Found :(" ]
                , p [ class "mv0 f4 f3-ns lh-copy" ] [ text "Whoops, looks like the page you are looking for does not exist..." ]
                , a [ Route.href Route.Home, class "db mw5 center pa3 link b bg-blue br2 near-white hover-bg-light-blue hover-near-black" ] [ text "Go back to the homepage" ]
                ]
            ]
    }
