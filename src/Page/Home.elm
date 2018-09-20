module Page.Home exposing
    ( Model
    , Msg(..)
    , init
    , subscriptions
    , update
    , view
    , viewBanner
    )

{-| The homepage. You can get here via either the / route.
-}

import Geolocation as Geo
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Location as L
import ServiceWorker as SW
import Task exposing (Task)
import Time
import Ui exposing (calloutContainer, heading, paragraph, prompt, styledButtonBlue)



-- MODEL


type alias Model =
    { timeZone : Time.Zone
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    , location : GeolocationData
    }


type GeolocationData
    = NotAsked
    | Got Geo.LocationResult


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , swUpdate = SW.updateNone
      , installPrompt = SW.installPromptNone
      , location = NotAsked
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content = viewInner model
    }


viewInner : Model -> Html Msg
viewInner model =
    div []
        [ Ui.centeredContainer
            []
            [ div [ class "vs4" ]
                [ div [ class "vs3" ]
                    [ viewBanner
                    , div [] [ a [ class "link underline", href "/404" ] [ text "Demo 404 page" ] ]
                    ]
                , div [ class "vs3" ]
                    [ Ui.styledButtonBlue [ onClick GetLocation ] [ text "Get Location" ]
                    , viewLocation model.location
                    ]
                ]
            , viewUpdatePrompt model.swUpdate
            , viewInstallPrompt model.installPrompt
            ]
        ]


viewLocation : GeolocationData -> Html Msg
viewLocation locationData =
    case locationData of
        NotAsked ->
            div [] []

        Got locationRes ->
            case locationRes of
                Ok location ->
                    div [ class "vs3" ]
                        [ heading 2 [] [ text "Got location:" ]
                        , div []
                            [ text <|
                                String.fromFloat (L.latToFloat location.lat)
                                    ++ ", "
                                    ++ String.fromFloat (L.lonToFloat location.lon)
                            ]
                        ]

                Err error ->
                    div [ class "vs3" ]
                        [ heading 2 [] [ text "Error getting location:" ]
                        , div []
                            [ text <| Geo.errorToString error
                            ]
                        ]


viewUpdatePrompt : SW.SwUpdate -> Html Msg
viewUpdatePrompt swUpdate =
    SW.viewSwUpdate swUpdate
        { none = div [] []
        , available =
            calloutContainer []
                [ prompt []
                    [ h2 [ class "mr3 mv0 f5 fw4 lh-title" ] [ text "A new version is available. You can reload now to get it." ]
                    , div [ class "flex" ]
                        [ styledButtonBlue [ onClick AcceptUpdate, class "ma2" ] [ text "Reload" ]
                        , styledButtonBlue [ onClick DeferUpdate, class "ma2" ] [ text "Later" ]
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
            calloutContainer []
                [ prompt []
                    [ div [ class "measure vs3" ]
                        [ h2 [ class "mr3 mv0 f5 fw4 lh-title" ] [ text "Add Ephemeral to home screen?" ]

                        -- , paragraph [] [ text "You can install Ephemeral to your homescreen for\n            quicker access and standalone use. It will still\n            be available offline through the browser if you\n            do not." ]
                        ]
                    , div [ class "flex" ]
                        [ styledButtonBlue [ onClick AcceptInstallPrompt, class "ma2" ] [ text "Add" ]
                        , styledButtonBlue [ onClick DeferInstallPrompt, class "ma2" ] [ text "Dismiss" ]
                        ]
                    ]
                ]
        }


viewBanner : Html msg
viewBanner =
    div [ class "vs3" ]
        [ heading 1 [] [ text "Ephemeral" ]
        , paragraph [] [ text "Write down words as you encounter them." ]
        ]



-- UPDATE


type Msg
    = GotTimeZone Time.Zone
    | FromServiceWorker SW.ToElm
    | FromGeolocation Geo.ToElm
    | AcceptUpdate
    | DeferUpdate
    | AcceptInstallPrompt
    | DeferInstallPrompt
    | GetLocation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        FromServiceWorker swMsg ->
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

        FromGeolocation geoMsg ->
            case geoMsg of
                Geo.GotLocation locationRes ->
                    ( { model | location = Got locationRes }, Cmd.none )

                Geo.DecodingError err ->
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

        GetLocation ->
            ( model, Geo.getLocation )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FromServiceWorker SW.sub
        , Sub.map FromGeolocation Geo.sub
        ]
