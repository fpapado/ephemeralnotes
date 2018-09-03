module Page.Home exposing (Model, Msg(..), init, subscriptions, update, view, viewBanner)

{-| The homepage. You can get here via either the / route.
-}

import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import ServiceWorker as SW
import Task exposing (Task)
import Time
import Ui exposing (bottomBanner, heading, paragraph)



-- MODEL


type alias Model =
    { timeZone : Time.Zone
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    }


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , swUpdate = SW.updateNone
      , installPrompt = SW.installPromptNone
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Ephemeral"
    , content = viewInner model
    }


viewInner : Model -> Html Msg
viewInner model =
    div
        [ class "home-page" ]
        [ viewBanner
        , a [ class "link underline", href "/404" ] [ text "404 page" ]
        , viewUpdatePrompt model.swUpdate
        , viewInstallPrompt model.installPrompt
        ]


viewUpdatePrompt : SW.SwUpdate -> Html Msg
viewUpdatePrompt swUpdate =
    SW.viewSwUpdate swUpdate
        { none = div [] []
        , available =
            bottomBanner []
                [ div [ class "pa3 flex justify-center items-center bg-white near-black shadow-1 animated fadeInUp" ]
                    [ h2 [ class "mr3 mv0 f5 fw7 lh-title" ] [ text "Update available" ]
                    , div [ class "hs3" ]
                        [ button [ onClick AcceptUpdate ] [ text "Accept" ]
                        , button [ onClick DeferUpdate ] [ text "Later" ]
                        ]
                    ]
                ]
        , accepted = div [] []
        , defered = div [] []
        }


viewInstallPrompt : SW.InstallPrompt -> Html Msg
viewInstallPrompt installPrompt =
    SW.viewInstallPrompt installPrompt
        { none = div [] []
        , available =
            bottomBanner []
                [ div [ class "pa3 flex justify-center items-center bg-white near-black shadow-1 animated fadeInUp" ]
                    [ div [ class "measure vs3" ]
                        [ h2 [ class "mr3 mv0 f5 fw7 lh-title" ] [ text "Update available" ]
                        , paragraph [] [ text "You can install Ephemeral to your homescreen for\n            quicker access and standalone use. It will still\n            be available offline through the browser if you\n            do not." ]
                        ]
                    , div [ class "hs3" ]
                        [ button [ onClick AcceptInstallPrompt ] [ text "Install" ]
                        , button [ onClick DeferInstallPrompt ] [ text "Dismiss" ]
                        ]
                    ]
                ]
        }


viewBanner : Html msg
viewBanner =
    div [ class "banner" ]
        [ div [ class "container" ]
            [ heading [] [ text "Ephemeral" ]
            , p [] [ text "Write down words as you encounter them." ]
            ]
        ]



-- UPDATE


type Msg
    = GotTimeZone Time.Zone
    | ServiceWorker SW.ToElm
    | AcceptUpdate
    | DeferUpdate
    | AcceptInstallPrompt
    | DeferInstallPrompt


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        ServiceWorker swMsg ->
            case swMsg of
                SW.UpdateAvailable ->
                    ( { model | swUpdate = SW.updateAvailable }
                    , Cmd.none
                    )

                SW.BeforeInstallPrompt ->
                    ( { model | installPrompt = SW.installPromptAvailable }
                    , Cmd.none
                    )

                SW.DecodingError err ->
                    ( model, Cmd.none )

        AcceptUpdate ->
            ( { model | swUpdate = SW.updateAccepted }, SW.acceptUpdate )

        DeferUpdate ->
            ( { model | swUpdate = SW.updateDefered }, SW.deferUpdate )

        -- TODO: Fix None to Accepted/Defered
        AcceptInstallPrompt ->
            ( { model | installPrompt = SW.installPromptNone }, SW.acceptInstallPrompt )

        DeferInstallPrompt ->
            ( { model | installPrompt = SW.installPromptNone }, SW.deferInstallPrompt )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ServiceWorker SW.sub
