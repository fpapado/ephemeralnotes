port module DarkMode exposing
    ( Mode(..)
    , ToElm(..)
    , inverse
    , modeToString
    , sub
    , toggleMode
    , viewSwitch
    )

import Html as H exposing (Html, button, div, span, text)
import Html.Attributes as HA exposing (class)
import Html.Events as HE exposing (onClick)
import Json.Decode as JD
import Json.Encode as JE



-- PORTS


port darkModeFromElm : JD.Value -> Cmd msg


port darkModeToElm : (JD.Value -> msg) -> Sub msg



-- TYPES


type Mode
    = Light
    | Dark


type ToElm
    = ModeSet Mode
    | BadMessage JD.Error


type FromElm
    = SetMode Mode



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> darkModeFromElm


toggleMode : Mode -> Cmd msg
toggleMode mode =
    send (SetMode (inverse mode))


inverse : Mode -> Mode
inverse mode =
    case mode of
        Light ->
            Dark

        Dark ->
            Light



--IN


sub : Sub ToElm
sub =
    darkModeToElm (JD.decodeValue toElmDecoder)
        |> Sub.map
            (\subMsg ->
                case subMsg of
                    Ok msg ->
                        msg

                    Err err ->
                        BadMessage err
            )



-- JSON


encodeFromElm : FromElm -> JE.Value
encodeFromElm data =
    case data of
        SetMode mode ->
            JE.object
                [ ( "tag", JE.string "SetMode" )
                , ( "data", JE.string (modeToString mode) )
                ]


modeToString : Mode -> String
modeToString mode =
    case mode of
        Light ->
            "Light"

        Dark ->
            "Dark"


toElmDecoder : JD.Decoder ToElm
toElmDecoder =
    JD.field "tag" JD.string
        |> JD.andThen toElmInnerDecoder


toElmInnerDecoder : String -> JD.Decoder ToElm
toElmInnerDecoder tag =
    case tag of
        "ModeSet" ->
            JD.field "data" JD.string
                |> JD.andThen modeDecoder
                |> JD.map ModeSet

        _ ->
            JD.fail ("Unknown message: " ++ tag)


modeDecoder : String -> JD.Decoder Mode
modeDecoder str =
    case str of
        "Light" ->
            JD.succeed Light

        "Dark" ->
            JD.succeed Dark

        _ ->
            JD.fail ("Unknown theme mode: " ++ str)



-- VIEW


{-| An enhanced button, with aria-pressed=true|false. As a switch, it implies immediate action rather than form submission.
@see <https://scottaohara.github.io/aria-switch-control/>
@note we are not using the role="switch"+aria-checked=true|false, due to compatibility issues <https://scottaohara.github.io/a11y_styled_form_controls/src/checkbox--switch/>
-}
viewSwitch : { onClick : msg, mode : Mode } -> Html msg
viewSwitch { onClick, mode } =
    let
        textLabel =
            modeToString mode

        isChecked =
            case mode of
                Dark ->
                    True

                Light ->
                    False
    in
    div [ class "fw6 f4" ]
        [ button
            [ class "switch-toggle"
            , HA.attribute "aria-pressed" (boolToStringAttr isChecked)
            , HE.onClick onClick
            ]
            [ text "Dark mode"
            , span [ HA.attribute "aria-hidden" "true" ] []
            ]
        ]


boolToStringAttr : Bool -> String
boolToStringAttr bool =
    case bool of
        True ->
            "true"

        False ->
            "false"
