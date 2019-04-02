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
    | NoOp


type State
    = Editing
    | WaitingForTime
    | WaitingForLocation
    | WaitingForSave
    | EditingWithError Error


type Error
    = GeolocationError Geo.Error
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
                                next =
                                    -- TODO: The fact that we need to pattern match time even though we *know* we have it, is a hint that we should
                                    -- rething the data modelling. Perhaps something that makes the sequencing more obvious? I'm not sure to what though :)
                                    case form.time of
                                        RemoteData.Success time ->
                                            case locationData of
                                                RemoteData.Success location ->
                                                    let
                                                        entryPartial : Entry.EntryV1Partial
                                                        entryPartial =
                                                            { front = form.input.front
                                                            , back = form.input.back
                                                            , time = time
                                                            , location = location
                                                            }
                                                    in
                                                    ( { form | location = locationData, state = WaitingForSave }, Store.storeEntry entryPartial )

                                                -- On geolocation error, notify the user, and do not save
                                                RemoteData.Failure error ->
                                                    ( { form | location = locationData, state = EditingWithError (GeolocationError error) }, Cmd.none )

                                                _ ->
                                                    ( form, Cmd.none )

                                        _ ->
                                            ( form, Cmd.none )
                            in
                            next

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
                                    ( { form | state = EditingWithError SavingError }, Cmd.none )

                        _ ->
                            ( form, Cmd.none )

                NoOp ->
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


isEditable : State -> Bool
isEditable state =
    case state of
        Editing ->
            True

        EditingWithError err ->
            True

        _ ->
            False


view : Form -> Html Msg
view form_ =
    let
        -- NOTE: We make the fields "Read only", and make the submit a noOp, if we are in any
        -- state other than editing.
        -- We want users to not edit the field while it is submitting, and must style and announce as such
        -- The 'disabled' attribute is pretty bad for screen reader announcements, so we prefer readonly and
        -- NoOp on any relevant events :)
        areFieldsReadOnly =
            not (isEditable form_.state)

        noOpIfReadOnly msg =
            if areFieldsReadOnly then
                NoOp

            else
                msg

        inputBgCls =
            if areFieldsReadOnly then
                "bg-light-gray"

            else
                "bg-white"

        buttonText =
            case form_.state of
                Editing ->
                    "Save entry"

                WaitingForTime ->
                    "Getting time..."

                WaitingForLocation ->
                    "Getting location..."

                WaitingForSave ->
                    "Saving..."

                EditingWithError err ->
                    "Save entry"

        viewFormError =
            case form_.state of
                EditingWithError err ->
                    viewError err

                _ ->
                    div [] []
    in
    form [ class "vs3 vs4-ns", HE.onSubmit (noOpIfReadOnly PressedSave), HA.autocomplete False ]
        [ subHeading 2 [ class "decor" ] [ text "Add Entry" ]
        , div [ class "vs3 vs4-ns mw6" ]
            [ viewFormError
            , div [ class "vs2" ]
                [ label
                    [ class "db fw6 f5 f4-ns"
                    , HA.for "entry-front"
                    ]
                    [ text "Word" ]
                , input
                    [ class "mw6 w-100 db pa2 fw4 f5 f4-ns ba bw1 b--near-black br1 focus-shadow-light"
                    , class inputBgCls
                    , HA.type_ "text"
                    , HA.id "entry-front"
                    , HA.name "front"
                    , HE.onInput (noOpIfReadOnly << FrontChanged)
                    , HA.value form_.input.front
                    , HA.placeholder "Ephemeral"
                    , HA.readonly areFieldsReadOnly
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
                    , class inputBgCls
                    , HA.type_ "text"
                    , HA.id "entry-back"
                    , HA.name "back"
                    , HE.onInput (noOpIfReadOnly << BackChanged)
                    , HA.value form_.input.back
                    , HA.placeholder "Lasting a short time, fleeting"
                    , HA.readonly areFieldsReadOnly
                    ]
                    []
                ]
            , div [ class "flex" ]
                [ input
                    [ class "db mr2 f5 f4-ns"
                    , class inputBgCls
                    , HA.type_ "checkbox"
                    , HA.id "entry-location"
                    , HA.name "save location"
                    , HE.onCheck (noOpIfReadOnly << LocationToggled)
                    , HA.checked form_.input.saveLocation
                    , HA.readonly areFieldsReadOnly
                    ]
                    []
                , label
                    [ class "db fw6 f5 f4-ns"
                    , HA.for "entry-location"
                    ]
                    [ text "Save location" ]
                ]
            , styledButtonBlue areFieldsReadOnly
                [ class "w-100" ]
                [ text buttonText
                ]
            ]
        ]


viewError : Error -> Html msg
viewError error =
    let
        humanText =
            case error of
                GeolocationError Geo.PermissionDenied ->
                    "The location permission was denied, now or in the past. Perhaps there is a setting in your browser? For now, you can save the note without a location, using the checkbox below."

                GeolocationError Geo.PositionUnavailable ->
                    "There was an error when acquiring your location. For now, you can save the note without a location, using the checkbox below."

                GeolocationError Geo.Timeout ->
                    "Acquiring your location took too long. This can happen sometimes. For now, you can save the note without a location, using the checkbox below."

                SavingError ->
                    "There was an internal error when saving the note locally. Sorry about that.."
    in
    div [ class "vs1 pa3 bg-washed-red ba bw1 br2 b--light-red" ]
        [ subHeading 3 [] [ text "Error" ]
        , paragraph [] [ text humanText ]
        ]
