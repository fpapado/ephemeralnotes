module Page.NotFound exposing (view)

import Html exposing (Html, a, div, h1, img, p, text)
import Html.Attributes exposing (alt, class, src)
import Route exposing (Route)
import Ui exposing (buttonLink, heading)



-- VIEW


view : { title : String, content : Html msg }
view =
    { title = "Page Not Found"
    , content =
        div [ class "flex flex-auto flex-column justify-center" ]
            [ div
                [ class "tc measure center vs4" ]
                [ heading 1 [] [ text "Not Found :(" ]
                , p [ class "mv0 f4 f3-ns lh-copy" ] [ text "Whoops, looks like the page you are looking for does not exist..." ]
                , buttonLink [ Route.href Route.Home ] [ text "Go back to the homepage" ]
                ]
            ]
    }
