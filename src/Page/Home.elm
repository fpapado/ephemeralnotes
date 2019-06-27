module Page.Home exposing
    ( Model
    , Msg(..)
    , init
    , subscriptions
    , update
    , view
    )

{-| The homepage. You can get here via either the / route.
-}

import AddEntryForm as Form exposing (Form)
import DarkMode
import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Geolocation as Geo
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import Iso8601
import Json.Decode as JD
import Json.Encode as JE
import Location as L
import Log
import RemoteData exposing (RemoteData)
import Route
import Store
import Svg.Attributes
import Svg.NoData
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    { form : Form
    }


type alias Context =
    { entries : RemoteData String (List Entry)
    }


init : ( Model, Cmd Msg )
init =
    ( { form = Form.empty }, Cmd.none )



-- VIEW


view : Context -> Model -> { title : String, content : Html Msg }
view context model =
    { title = "Home"
    , content = viewContent context model
    }


viewContent : Context -> Model -> Html Msg
viewContent context model =
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
                , div [ class "mw5" ] [ DarkMode.viewSwitch DarkMode.Dark ]
                , section [] [ Html.map FormMsg (Form.view model.form) ]
                , section [ class "vs3 vs4-ns" ]
                    [ subHeading 2 [] [ text "Entries" ]
                    , viewEntries context.entries ( formInput.front, formInput.back )
                    ]
                , section [] [ viewAddToHomeScreen ]
                ]
            ]
        ]


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
            , li [ class "flex flex-column pa3 br2 bg-white ba bw1 b--near-black shadow-4 near-black" ]
                [ div [ class "vs2 mb3" ]
                    [ paragraph [ class "fw6" ] [ text entry.front ]
                    , paragraph [] [ text entry.back ]
                    ]
                , div [ class "mt-auto vs2" ]
                    [ paragraph []
                        [ text <| L.toGpsPrecisionString entry.location
                        ]
                    , paragraph []
                        [ Html.node "local-time"
                            [ HA.attribute "datetime" (Iso8601.fromTime entry.time)
                            , HA.attribute "month" "short"
                            , HA.attribute "day" "numeric"
                            , HA.attribute "year" "numeric"
                            , HA.attribute "hour" "numeric"
                            , HA.attribute "minute" "numeric"
                            ]
                            []
                        ]
                    ]
                ]
            )


viewAddToHomeScreen =
    div [ class "vs3 vs4-ns", HA.attribute "open" "true" ]
        [ subHeading 2
            [ class "dib v-mid" ]
            [ text "Add to Home Screen" ]
        , paragraph
            [ class "measure" ]
            [ text "You can add Ephemeral to your home screen for quicker access and standalone use. It will always be available offline through your web browser." ]
        ]



-- UPDATE


type Msg
    = NoOp
    | FormMsg Form.Msg
    | FromGeolocation Geo.ToElm
    | FromStore Store.ToElm


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Form
        FormMsg formTransitionMsg ->
            let
                ( newForm, cmd ) =
                    Form.update formTransitionMsg model.form
            in
            ( { model | form = newForm }, Cmd.map FormMsg cmd )

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

        -- Store
        -- The form cares about GotEntry
        FromStore storeMsg ->
            case storeMsg of
                Store.GotEntry entryRes ->
                    let
                        entryData =
                            RemoteData.fromResult entryRes

                        -- Update the form when we get a new entry
                        -- Internally, the form knows only to reset when the save msg arrives when it is waiting for one
                        -- NOTE: In the future, we could be attaching an id here, to de-duplicate and truly make it impossible
                        -- Get the result into the shape the form wants
                        formResult =
                            entryRes
                                |> Result.map (\entry -> ())
                                |> Result.mapError (\err -> ())

                        ( newForm, cmd ) =
                            Form.update (Form.GotSaveResult formResult) model.form
                    in
                    -- TODO: Consider notification
                    ( { model | form = newForm }, Cmd.map FormMsg cmd )

                _ ->
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FromGeolocation Geo.sub
        , Sub.map FromStore Store.sub
        ]
