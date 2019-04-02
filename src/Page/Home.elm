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
    , location : GeolocationData
    , entries : RemoteData String (List Entry)
    , form : Form
    }


type alias Form =
    { front : String
    , back : String
    , saveLocation : Bool
    }


emptyForm : Form
emptyForm =
    { front = ""
    , back = ""
    , saveLocation = True
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
                    , viewEntries model.entries ( model.form.front, model.form.back )
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
    form [ class "vs3 vs4-ns", HE.onSubmit FormSubmitClicked, HA.autocomplete False ]
        [ subHeading 2 [ class "decor" ] [ text "Add Entry" ]
        , div [ class "vs3 vs4-ns mw6" ]
            [ div [ class "vs2" ]
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
                    , HE.onInput FormFrontChanged
                    , HA.value form_.front
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
                    , HE.onInput FormBackChanged
                    , HA.value form_.back
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
                    , HE.onCheck FormLocationToggled
                    , HA.checked form_.saveLocation
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
    | GetLocation
    | FormSubmitClicked
    | FormSubmittedOk
    | FormFrontChanged String
    | FormBackChanged String
    | FormLocationToggled Bool


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

                Store.GotEntry entryRes ->
                    let
                        entryData =
                            RemoteData.fromResult entryRes

                        -- Merge the two data sources
                        newEntries =
                            RemoteData.map2 (\entry entries -> entry :: entries) entryData model.entries
                    in
                    --TODO: Consider notification
                    ( { model | entries = newEntries }, Cmd.none )

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

        GetLocation ->
            ( model, Geo.getLocation )

        -- Form
        FormFrontChanged front ->
            let
                form =
                    model.form

                newForm =
                    { form | front = front }
            in
            ( { model | form = newForm }, Cmd.none )

        FormBackChanged back ->
            let
                form =
                    model.form

                newForm =
                    { form | back = back }
            in
            ( { model | form = newForm }, Cmd.none )

        FormLocationToggled toggle ->
            let
                form =
                    model.form

                newForm =
                    { form | saveLocation = toggle }
            in
            ( { model | form = newForm }, Cmd.none )

        -- TODO: On Form submit:
        -- - TODO: Set form "submitting" state
        -- - get location if specified
        -- - tie that to the form somehow / prevent the form from being edited and the button clicked
        -- - add a "loading" to the button
        -- - if failed, show message
        -- - if succeeded, send to JS side for storing
        -- - keep "loading" with "saving"
        -- - if succeeded, reset form
        -- - if failed, show message, do not reset
        -- NOTE: need a way to relate the GotResult/SavedOk to the form submit, maybe through some key?
        -- NOTE: Need a way to encode partials, e.g Entry.encodePartial
        -- NOTE: Check JS-side for the uuid generation
        FormSubmitClicked ->
            let
                saveCmd =
                    let
                        lat =
                            L.latFromFloat 0

                        lon =
                            L.lonFromFloat 0
                    in
                    case ( lat, lon ) of
                        ( Just x, Just y ) ->
                            let
                                entryPartial =
                                    { front = model.form.front
                                    , back = model.form.back
                                    , time = Time.millisToPosix 0
                                    , location = { lat = x, lon = y }
                                    }
                            in
                            Store.storeEntry entryPartial

                        _ ->
                            Cmd.none
            in
            ( model, saveCmd )

        FormSubmittedOk ->
            ( { model | form = emptyForm }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FromServiceWorker SW.sub
        , Sub.map FromGeolocation Geo.sub
        , Sub.map FromStore Store.sub
        ]
