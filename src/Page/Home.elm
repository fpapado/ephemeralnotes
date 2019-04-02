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


type alias Form =
    { input : FormInput
    , location : RemoteData Geo.Error L.LatLon
    , time : RemoteData Never Time.Posix
    , state : FormState
    }


type FormTransitionMsg
    = FrontChanged String
    | BackChanged String
    | LocationToggled Bool
    | PressedSave
    | GotTime Time.Posix
    | GotLocation (RemoteData Geo.Error L.LatLon)
    | GotSaveResult (Result FormError ())


type FormState
    = Editing
    | WaitingForTime
    | WaitingForLocation
    | WaitingForSave
    | FormError FormError


type FormError
    = GeolocationFailed
    | SavingError


type alias FormInput =
    { front : String
    , back : String
    , saveLocation : Bool
    }


{-| Update the form, skipping invalid transitions
-}
updateForm : FormTransitionMsg -> Form -> ( Form, Cmd FormTransitionMsg )
updateForm msg form =
    let
        newForm =
            case msg of
                FrontChanged front ->
                    let
                        input =
                            form.input

                        newInput =
                            { input | front = front }
                    in
                    ( { form | input = newInput }
                    , Cmd.none
                    )

                BackChanged back ->
                    let
                        input =
                            form.input

                        newInput =
                            { input | back = back }
                    in
                    ( { form | input = newInput }, Cmd.none )

                LocationToggled toggle ->
                    let
                        input =
                            form.input

                        newInput =
                            { input | saveLocation = toggle }
                    in
                    ( { form | input = newInput }, Cmd.none )

                PressedSave ->
                    case form.state of
                        Editing ->
                            ( { form | state = WaitingForTime }, Task.perform GotTime Time.now )

                        _ ->
                            ( form, Cmd.none )

                GotTime time ->
                    case form.state of
                        WaitingForTime ->
                            -- TODO: Depending on location save being toggled, transition to location or submission
                            -- Consider whether we should be calling updateForm in here as a short-circuit...
                            ( { form | time = RemoteData.succeed time, location = RemoteData.Loading, state = WaitingForLocation }, Geo.getLocation )

                        _ ->
                            ( form, Cmd.none )

                GotLocation locationData ->
                    case form.state of
                        -- TODO: Handle the location failing better
                        WaitingForLocation ->
                            let
                                saveCmd =
                                    case locationData of
                                        RemoteData.Success location ->
                                            case form.time of
                                                RemoteData.Success time ->
                                                    let
                                                        entryPartial : Entry.EntryV1Partial
                                                        entryPartial =
                                                            { front = form.input.front
                                                            , back = form.input.back
                                                            , time = time
                                                            , location = location
                                                            }
                                                    in
                                                    Store.storeEntry entryPartial

                                                _ ->
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                            in
                            ( { form | location = locationData, state = WaitingForSave }, saveCmd )

                        _ ->
                            ( form, Cmd.none )

                GotSaveResult res ->
                    case form.state of
                        WaitingForSave ->
                            case res of
                                -- Reset the form
                                Ok () ->
                                    ( { form | input = emptyInput, state = Editing }, Cmd.none )

                                Err formError ->
                                    ( { form | state = FormError formError }, Cmd.none )

                        _ ->
                            ( form, Cmd.none )
    in
    newForm


emptyForm : Form
emptyForm =
    { input = emptyInput
    , location = RemoteData.NotAsked
    , time = RemoteData.NotAsked
    , state = Editing
    }


emptyInput : FormInput
emptyInput =
    { front = ""
    , back = ""
    , saveLocation = True
    }



-- TODO: Spinner button, show when loading
-- | Loading Id


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , swUpdate = SW.updateNone
      , installPrompt = SW.installPromptNone
      , entries = RemoteData.Loading
      , form = emptyForm
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
            [ div [ class "vs4 vs5-ns" ]
                [ section [ class "vs3 vs4-ns" ]
                    [ heading 1 [] [ text "Ephemeral" ]
                    , paragraph [ class "measure" ] [ text "Ephemeral is a web app for writing down words and their translations, as you encounter them." ]
                    ]
                , section [] [ viewForm model.form ]
                , section [ class "vs3 vs4-ns" ]
                    [ subHeading 2 [] [ text "Entries" ]
                    , viewEntries model.entries ( model.form.input.front, model.form.input.back )
                    ]
                , section [] [ viewAbout ]
                ]
            , viewUpdatePrompt model.swUpdate
            , viewInstallPrompt model.installPrompt
            ]
        ]


viewAbout =
    details [ class "vs3", HA.attribute "open" "true" ]
        [ summary [ class "mw6" ]
            [ subHeading 2
                [ class "dib v-mid" ]
                [ text "Installing" ]
            ]
        , paragraph
            [ class "measure" ]
            [ text "You can install Ephemeral to your homescreen for quicker access and standalone use. It will still be available offline through the browser, even if you do not install it." ]
        ]


viewForm : Form -> Html Msg
viewForm form_ =
    form [ class "vs3 vs4-ns", HE.onSubmit (FormMsg PressedSave), HA.autocomplete False ]
        [ subHeading 2 [ class "decor" ] [ text "Add Entry" ]
        , div [ class "vs3 vs4-ns mw6" ]
            [ paragraph [ class "pa3 bg-washed-yellow ba bw1 br2 b--yellow" ]
                [ span [ class "fw6" ] [ text "Note: " ]
                , span [] [ text "Location and Time saving are not yet implemented. We will save these with defaults for now." ]
                ]
            , div [ class "vs2" ]
                [ label
                    [ class "db fw6 f5 f4-ns"
                    , HA.for "entry-front"
                    ]
                    [ text "Word" ]
                , input
                    [ class "mw6 w-100 db pa2 fw4 f5 f4-ns ba bw1 b--near-black br1 focus-shadow-light"
                    , HA.type_ "text"
                    , HA.id "entry-front"
                    , HA.name "front"
                    , HE.onInput (FormMsg << FrontChanged)
                    , HA.value form_.input.front
                    , HA.placeholder "Ephemeral"
                    ]
                    []
                ]
            , div [ class "vs2" ]
                [ label
                    [ class "db fw6 f5 f4-ns"
                    , HA.for "entry-back"
                    ]
                    [ text "Translation" ]
                , input
                    [ class "mw6 w-100 db pa2 fw4 f5 f4-ns ba bw1 b--near-black br1 focus-shadow-light"
                    , HA.type_ "text"
                    , HA.id "entry-back"
                    , HA.name "back"
                    , HE.onInput (FormMsg << BackChanged)
                    , HA.value form_.input.back
                    , HA.placeholder "Lasting a short time, fleeting"
                    ]
                    []
                ]
            , div [ class "flex" ]
                [ input
                    [ class "db mr2 f5 f4-ns"
                    , HA.type_ "checkbox"
                    , HA.id "entry-location"
                    , HA.name "save location"
                    , HE.onCheck (FormMsg << LocationToggled)
                    , HA.checked form_.input.saveLocation
                    ]
                    []
                , label
                    [ class "db fw6 f5 f4-ns"
                    , HA.for "entry-location"
                    ]
                    [ text "Save location" ]
                ]
            , styledButtonBlue [ class "w-100" ]
                [ text "Save entry"
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
                            [ styledButtonBlue [ onClick AcceptUpdate, class "mr2" ] [ text "Reload" ]
                            , styledButtonBlue [ onClick DeferUpdate ] [ text "Later" ]
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
                            [ h2 [ class "mv0 f5 fw4 lh-title" ] [ text "Add Ephemeral to home screen?" ]
                            ]
                        , div [ class "ma2 flex" ]
                            [ styledButtonBlue [ onClick AcceptInstallPrompt, class "mr2" ] [ text "Add" ]
                            , styledButtonBlue [ onClick DeferInstallPrompt ] [ text "Dismiss" ]
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
    | FormMsg FormTransitionMsg


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
                            updateForm (GotLocation (RemoteData.fromResult locationRes)) model.form
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
                                |> Result.mapError (\err -> SavingError)

                        ( newForm, cmd ) =
                            updateForm (GotSaveResult formResult) model.form
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
                    updateForm formTransitionMsg model.form
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
