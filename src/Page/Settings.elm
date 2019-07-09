module Page.Settings exposing
    ( Msg
    , update
    , view
    )

import DarkMode
import Html exposing (Html, div, text)
import Html.Attributes as HA exposing (class)
import Ui exposing (..)



-- MODEL


type alias Context =
    { darkMode : DarkMode.Mode
    }



-- UPDATE


type Msg
    = ToggleDarkMode DarkMode.Mode


update : Msg -> Cmd Msg
update msg =
    case msg of
        -- DarkMode
        -- TODO: Could do some optimistic UI updates here by storing it in themodel?
        ToggleDarkMode mode ->
            DarkMode.toggleMode mode



-- VIEW


view : Context -> { title : String, content : Html Msg }
view { darkMode } =
    { title = "Settings"
    , content = viewContent darkMode
    }


viewContent : DarkMode.Mode -> Html Msg
viewContent darkMode =
    let
        darkModeDescriptionId =
            "dark-mode-desc"
    in
    div []
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div []
                    [ heading 1 [] [ text "Settings" ]
                    , div [ class "vs2 f4 measure" ]
                        [ DarkMode.viewSwitch
                            { onClick = ToggleDarkMode darkMode
                            , describedBy = Just darkModeDescriptionId
                            , mode = darkMode
                            }
                        , paragraphSmall
                            [ HA.id darkModeDescriptionId ]
                            [ text "Your preference will be saved and take precedence over system settings."
                            ]
                        ]
                    ]
                , div [ class "vs3" ]
                    [ subHeading 2 [] [ text "System Information" ]
                    , div [ class "vs3" ]
                        [ div [ class "mv0 f5 measure" ] [ Html.node "system-info" [] [] ]
                        ]
                    ]
                ]
            ]
        ]
