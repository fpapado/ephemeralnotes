module Page.About exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Ui exposing (..)


view : { title : String, content : Html msg }
view =
    { title = "About"
    , content = viewContent
    }


viewContent : Html msg
viewContent =
    div []
        [ centeredContainer
            []
            [ div [ class "vs4" ]
                [ heading 1 [] [ text "About" ]
                , div [ class "vs3 f4 measure" ]
                    []
                ]
            ]
        ]
