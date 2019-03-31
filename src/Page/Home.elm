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

import Asset
import Entry.Entry as Entry exposing (Entry)
import Geolocation as Geo
import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Location as L
import RemoteData exposing (RemoteData)
import ServiceWorker as SW
import Store
import Task exposing (Task)
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    { timeZone : Time.Zone
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    , location : GeolocationData
    , entries : RemoteData String (List Entry)
    }


type GeolocationData
    = NotAsked
    | Got Geo.LocationResult



-- TODO: Spinner button, show when loading
-- | Loading Id


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , swUpdate = SW.updateNone
      , installPrompt = SW.installPromptNone
      , location = NotAsked
      , entries = RemoteData.Loading
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , Store.getEntries

        -- Alternative: get the entries as a flag
        -- , GetEntries ...?
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
                    [ subHeading 2 [] [ text "Entries" ]
                    , viewEntries model.entries
                    ]
                ]
            , viewUpdatePrompt model.swUpdate
            , viewInstallPrompt model.installPrompt
            ]
        ]


viewEntries : RemoteData String (List Entry) -> Html Msg
viewEntries entryData =
    case entryData of
        RemoteData.NotAsked ->
            paragraph [] [ text "Not asked for entries yet" ]

        RemoteData.Loading ->
            paragraph [ class "animated fadeIn delay h5" ] [ text "Loading entries..." ]

        RemoteData.Failure err ->
            paragraph []
                [ text <| "Error getting entries: " ++ err
                ]

        RemoteData.Success entries ->
            viewEntryList entries


viewEntryList : List Entry -> Html Msg
viewEntryList entryList =
    case entryList of
        [] ->
            div
                [ class "vs3 tc" ]
                [ div [ class "mw4 mw5-l center" ]
                    [ div [ class "aspect-ratio aspect-ratio--1x1" ]
                        [ img (class "aspect-ratio--object db" :: Asset.toAttr Asset.noData) []
                        ]
                    ]
                , paragraph []
                    [ text "No entries yet. Why don't you add one? :)" ]
                ]

        -- TODO: HTML.keyed
        entries ->
            div [] (List.map viewEntry entries)


viewEntry : Entry -> Html Msg
viewEntry ambiguousEntry =
    case ambiguousEntry of
        Entry.V1 entry ->
            div []
                [ text entry.front
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
                        [ subHeading 2 [] [ text "Got location:" ]
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
    | FromStore Store.ToElm
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

        FromStore storeMsg ->
            case storeMsg of
                Store.GotEntries entries ->
                    ( { model | entries = RemoteData.Success entries }, Cmd.none )

                Store.DecodingError err ->
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
        , Sub.map FromStore Store.sub
        ]
