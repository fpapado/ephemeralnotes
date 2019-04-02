module AddEntryForm exposing
    ( Error
    , Form
    , Input
    , Msg(..)
    , State
    , empty
    , emptyInput
    , getInput
    , update
    , view
    )

import Entry.Entry as Entry exposing (Entry)
import Geolocation as Geo
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Location as L
import RemoteData exposing (RemoteData)
import Store
import Task
import Time
import Ui exposing (..)


type alias Form =
    { input : Input
    , location : RemoteData Geo.Error L.LatLon
    , time : RemoteData Never Time.Posix
    , state : State
    }


type Msg
    = FrontChanged String
    | BackChanged String
    | LocationToggled Bool
    | PressedSave
    | GotTime Time.Posix
    | GotLocation (RemoteData Geo.Error L.LatLon)
    | GotSaveResult (Result () ())


type State
    = Editing
    | WaitingForTime
    | WaitingForLocation
    | WaitingForSave
    | Error Error


type Error
    = GeolocationFailed
    | SavingError


type alias Input =
    { front : String
    , back : String
    , saveLocation : Bool
    }


{-| Update the form, skipping invalid transitions
-}
update : Msg -> Form -> ( Form, Cmd Msg )
update msg form =
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

                                Err () ->
                                    ( { form | state = Error SavingError }, Cmd.none )

                        _ ->
                            ( form, Cmd.none )
    in
    newForm


empty : Form
empty =
    { input = emptyInput
    , location = RemoteData.NotAsked
    , time = RemoteData.NotAsked
    , state = Editing
    }


emptyInput : Input
emptyInput =
    { front = ""
    , back = ""
    , saveLocation = True
    }


{-| A read-only view into the form's input. Useful in some niche cases.
-}
getInput : Form -> Input
getInput form_ =
    form_.input


view : Form -> Html Msg
view form_ =
    form [ class "vs3 vs4-ns", HE.onSubmit PressedSave, HA.autocomplete False ]
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
                    , HE.onInput FrontChanged
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
                    , HE.onInput BackChanged
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
                    , HE.onCheck LocationToggled
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
