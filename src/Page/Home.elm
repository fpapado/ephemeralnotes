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

import AddEntryForm as Form exposing (Form)
import Asset
import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Geolocation as Geo
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import Json.Decode as JD
import Location as L
import Log
import RemoteData exposing (RemoteData)
import ServiceWorker as SW
import Store
import Svg.Attributes
import Svg.NoData
import Task exposing (Task)
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    { timeZone : Time.Zone
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    , entries : RemoteData String (List Entry)
    , form : Form
    }


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , swUpdate = SW.updateNone
      , installPrompt = SW.installPromptNone
      , entries = RemoteData.Loading
      , form = Form.empty
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , Store.getEntries
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
    let
        formInput =
            Form.getInput model.form
    in
    div []
        [ Ui.centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ section [ class "vs3 vs4-ns" ]
                    [ heading 1 [] [ text "Ephemeral" ]
                    , paragraph [ class "measure" ] [ text "Ephemeral is a web app for writing down words and their translations, as you encounter them. It works offline and everything is stored locally, on your device." ]
                    ]
                , section [] [ Html.map FormMsg (Form.view model.form) ]
                , section [ class "vs3 vs4-ns" ]
                    [ subHeading 2 [] [ text "Entries" ]
                    , viewEntriesMap model.entries
                    , viewEntries model.entries ( formInput.front, formInput.back )
                    ]
                , section [] [ viewAbout ]
                ]
            , viewUpdatePrompt model.swUpdate
            , viewInstallPrompt model.installPrompt
            ]
        ]


viewAbout =
    div [ class "vs3", HA.attribute "open" "true" ]
        [ subHeading 2
            [ class "dib v-mid" ]
            [ text "Add to Home Screen" ]
        , paragraph
            [ class "measure" ]
            [ text "You can add Ephemeral to your home screen for quicker access and standalone use. It will always be available offline through your web browser." ]
        ]


viewEntriesMap : RemoteData String (List Entry) -> Html msg
viewEntriesMap entryData =
    let
        markerNodes =
            case entryData of
                RemoteData.NotAsked ->
                    []

                RemoteData.Loading ->
                    []

                RemoteData.Failure err ->
                    []

                RemoteData.Success entries ->
                    List.map viewEntryMarkerKeyed entries
    in
    Keyed.node "leaflet-map"
        [ HA.attribute "latitude" "60.1699"
        , HA.attribute "longitude" "24.9384"
        , HA.attribute "zoom" "12"
        ]
        markerNodes


viewEntryMarkerKeyed : Entry -> ( String, Html msg )
viewEntryMarkerKeyed ambiguousEntry =
    case ambiguousEntry of
        Entry.V1 entry ->
            ( Entry.Id.toString entry.id
            , Html.node "leaflet-marker"
                [ HA.attribute "latitude" (String.fromFloat (L.latToFloat entry.location.lat))
                , HA.attribute "longitude" (String.fromFloat (L.lonToFloat entry.location.lon))
                ]
                [ div [ class "vs2" ]
                    [ paragraph [ class "fw6" ] [ text entry.front ]
                    , paragraph [] [ text entry.back ]
                    ]
                ]
            )


viewEntries : RemoteData String (List Entry) -> ( String, String ) -> Html Msg
viewEntries entryData entryTuple =
    case entryData of
        RemoteData.NotAsked ->
            paragraph [] [ text "Not asked for entries yet" ]

        RemoteData.Loading ->
            paragraph [ class "animated fadeIn delay h5" ] [ text "Loading entries..." ]

        RemoteData.Failure err ->
            div []
                [ paragraph [] [ text "Error getting entries" ]
                , pre []
                    [ text err
                    ]
                ]

        RemoteData.Success entries ->
            viewEntryList entries entryTuple


viewEntryList : List Entry -> ( String, String ) -> Html Msg
viewEntryList entryList ( front, back ) =
    case entryList of
        [] ->
            div
                [ class "vs3 tc" ]
                [ div [ class "mw5 center" ]
                    [ Svg.NoData.view ( "Ephemeral", "Lasting a short time, fleeting" ) ( front, back ) []
                    ]
                , paragraph []
                    [ text "No entries yet. Why don't you add one? :)" ]
                ]

        -- The list might change often, so we use Html.Keyed to help the diffs
        entries ->
            Keyed.node "ul"
                [ class "pl0 list grid-entries grid-entries--compact" ]
                (List.map viewEntryKeyed entries)


viewEntryKeyed : Entry -> ( String, Html Msg )
viewEntryKeyed ambiguousEntry =
    case ambiguousEntry of
        Entry.V1 entry ->
            ( Entry.Id.toString entry.id
            , li [ class "flex flex-column vs3 pa3 br2 bg-white ba bw1 b--near-black shadow-4 near-black" ]
                [ div [ class "vs2 mb3" ]
                    [ paragraph [ class "fw6" ] [ text entry.front ]
                    , paragraph [] [ text entry.back ]
                    ]
                , div [ class "mt-auto" ]
                    [ paragraph []
                        [ text <|
                            String.fromFloat (L.latToFloat entry.location.lat)
                                ++ ", "
                                ++ String.fromFloat (L.lonToFloat entry.location.lon)
                        ]
                    , paragraph [] [ text (String.fromInt <| Time.posixToMillis entry.time) ]
                    ]
                ]
            )


viewUpdatePrompt : SW.SwUpdate -> Html Msg
viewUpdatePrompt swUpdate =
    notificationRegion []
        [ SW.viewSwUpdate swUpdate
            { none = div [] []
            , available =
                calloutContainer []
                    [ prompt [ class "na2" ]
                        [ div [ class "measure ma2" ]
                            [ h2 [ class "mv0 f5 fw4 lh-title" ] [ text "A new version is available. You can reload now to get it." ]
                            ]
                        , div [ class "ma2 flex" ]
                            [ styledButtonBlue False [ onClick AcceptUpdate, class "mr2" ] [ text "Reload" ]
                            , styledButtonBlue False [ onClick DeferUpdate ] [ text "Later" ]
                            ]
                        ]
                    ]
            , accepted = div [] []
            , deferred = div [] []
            }
        ]


viewInstallPrompt : SW.InstallPrompt -> Html Msg
viewInstallPrompt installPrompt =
    notificationRegion []
        [ SW.viewInstallPrompt installPrompt
            { none = div [] []
            , available =
                calloutContainer []
                    [ prompt [ class "na2" ]
                        [ div [ class "measure ma2" ]
                            [ h2 [ class "mv0 f5 fw4 lh-title" ] [ text "Add Ephemeral to your home screen?" ]
                            ]
                        , div [ class "ma2 flex" ]
                            [ styledButtonBlue False [ onClick AcceptInstallPrompt, class "mr2" ] [ text "Add" ]
                            , styledButtonBlue False [ onClick DeferInstallPrompt ] [ text "Dismiss" ]
                            ]
                        ]
                    ]
            }
        ]


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
    | FormMsg Form.Msg


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
                    ( model, Log.error (JD.errorToString err) )

        FromGeolocation geoMsg ->
            case geoMsg of
                -- Only the form cares about geolocation
                Geo.GotLocation locationRes ->
                    let
                        ( newForm, cmd ) =
                            Form.update (Form.GotLocation (RemoteData.fromResult locationRes)) model.form
                    in
                    ( { model | form = newForm }, Cmd.map FormMsg cmd )

                Geo.DecodingError err ->
                    ( model, Log.error (JD.errorToString err) )

        FromStore storeMsg ->
            case storeMsg of
                Store.GotEntries entries ->
                    ( { model | entries = RemoteData.Success entries }, Cmd.none )

                -- The form cares about GotEntry
                Store.GotEntry entryRes ->
                    let
                        entryData =
                            RemoteData.fromResult entryRes

                        -- Merge the two data sources
                        newEntries =
                            RemoteData.map2 (\entry entries -> entry :: entries) entryData model.entries

                        -- Update the form as well!
                        -- Internally, the form knows only to reset when the save msg arrives when it is waiting for one
                        -- NOTE: In the future, we could be attaching an id here
                        -- Get the result into the shape the form wants
                        formResult =
                            entryRes
                                |> Result.map (\entry -> ())
                                |> Result.mapError (\err -> ())

                        ( newForm, cmd ) =
                            Form.update (Form.GotSaveResult formResult) model.form
                    in
                    -- TODO: Consider notification
                    ( { model | entries = newEntries, form = newForm }, Cmd.map FormMsg cmd )

                Store.BadMessage err ->
                    ( model, Log.error (JD.errorToString err) )

        AcceptUpdate ->
            ( { model | swUpdate = SW.updateAccepted }, SW.acceptUpdate )

        DeferUpdate ->
            ( { model | swUpdate = SW.updateDeferred }, SW.deferUpdate )

        -- TODO: Fix None to Accepted/Defered
        AcceptInstallPrompt ->
            ( { model | installPrompt = SW.installPromptNone }, SW.acceptInstallPrompt )

        DeferInstallPrompt ->
            ( { model | installPrompt = SW.installPromptNone }, SW.deferInstallPrompt )

        -- Form
        FormMsg formTransitionMsg ->
            let
                ( newForm, cmd ) =
                    Form.update formTransitionMsg model.form
            in
            ( { model | form = newForm }, Cmd.map FormMsg cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FromServiceWorker SW.sub
        , Sub.map FromGeolocation Geo.sub
        , Sub.map FromStore Store.sub
        ]
