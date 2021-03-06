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

import Browser.Dom as Dom
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
    | GotSaveResult (Result Store.RequestError ())
    | NoOp


type State
    = Editing
    | WaitingForTime
    | WaitingForLocation
    | WaitingForSave
    | EditingWithError Error


type Error
    = GeolocationError Geo.Error
    | SavingError Store.RequestError


type alias Input =
    { front : String
    , back : String
    , saveLocation : Bool
    }



-- Setup for focusing the error summary
-- We focus the summary to notify users of errors


errorSummaryId : String
errorSummaryId =
    "addEntryForm-summary"


focusErrorSummaryAndForget =
    Dom.focus errorSummaryId
        |> Task.attempt (\_ -> NoOp)


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

                        EditingWithError err ->
                            ( { form | state = WaitingForTime }, Task.perform GotTime Time.now )

                        _ ->
                            ( form, Cmd.none )

                GotTime time ->
                    case form.state of
                        WaitingForTime ->
                            -- Depending on location save being toggled, transition
                            -- to WaitingForLocation or short-circuit to WaitingForSave
                            case form.input.saveLocation of
                                True ->
                                    ( { form
                                        | time = RemoteData.succeed time
                                        , location = RemoteData.Loading
                                        , state = WaitingForLocation
                                      }
                                    , Geo.getLocation
                                    )

                                False ->
                                    -- TODO: Encoding as nullIsland is ugly, and will lead to more confusion in the view code
                                    -- perhaps we should just be using a Maybe? The one question then is persistence in IndexedDB?
                                    let
                                        entryPartial : Entry.EntryV1Partial
                                        entryPartial =
                                            { front = form.input.front
                                            , back = form.input.back
                                            , time = time
                                            , location = L.nullIsland
                                            }
                                    in
                                    ( { form | state = WaitingForSave }
                                    , Store.storeEntry entryPartial
                                    )

                        _ ->
                            ( form, Cmd.none )

                GotLocation locationData ->
                    case form.state of
                        WaitingForLocation ->
                            let
                                next =
                                    -- TODO: The fact that we need to pattern match time even though we *know* we have it, is a hint that we should
                                    -- rethink the data modelling. Perhaps something that makes the sequencing more obvious? I'm not sure to what though :)
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
                                                    ( { form | location = locationData, state = WaitingForSave }
                                                    , Store.storeEntry entryPartial
                                                    )

                                                -- On geolocation error, notify the user, and do not save
                                                RemoteData.Failure error ->
                                                    ( { form | location = locationData, state = EditingWithError (GeolocationError error) }
                                                    , focusErrorSummaryAndForget
                                                    )

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
                        -- We only care about "Got Save Result" messages if we are waiting for one!
                        WaitingForSave ->
                            case res of
                                -- All is well; reset the form.
                                Ok () ->
                                    ( { form | input = emptyInput, state = Editing }, Cmd.none )

                                -- Things went wrong, update the state and focus the error summary
                                Err err ->
                                    ( { form | state = EditingWithError (SavingError err) }
                                    , focusErrorSummaryAndForget
                                    )

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
                "bg-light-gray color-bg"

            else
                "bg-color-lighter"

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
                -- TODO: Add a "viewSuccess" here as well!
                EditingWithError err ->
                    viewError err

                _ ->
                    text ""
    in
    form [ class "vs3 vs4-ns", HE.onSubmit (noOpIfReadOnly PressedSave), HA.autocomplete False ]
        [ subHeading 2 [ class "decor" ] [ text "Add Entry" ]
        , div [ class "vs3 vs4-ns mw6" ]
            [ viewFormError
            , div [ class "vs2" ]
                [ label
                    [ class "db fw6 f-paragraph f4-ns"
                    , HA.for "entry-front"
                    ]
                    [ text "Word" ]
                , input
                    [ class "enhanced-input-text mw6 w-100 db pa2 fw4 f-paragraph f4-ns ba bw1 b--color-text color-text br1 focus-shadow-faint"
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
                    [ class "db fw6 f-paragraph f4-ns"
                    , HA.for "entry-back"
                    ]
                    [ text "Translation" ]
                , input
                    [ class "enhanced-input-text mw6 w-100 db pa2 fw4 f-paragraph f4-ns ba bw1 b--color-text color-text br1 focus-shadow-faint"
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
            , div []
                [ checkbox { id = "entry-location", name = "entry-location", isReadOnly = areFieldsReadOnly }
                    [ HE.onCheck (noOpIfReadOnly << LocationToggled)
                    , HA.checked form_.input.saveLocation
                    , HA.readonly areFieldsReadOnly
                    ]
                    "Save location"
                ]
            , primaryActionButton areFieldsReadOnly
                [ class "w-100" ]
                [ text buttonText
                ]
            ]
        ]


{-| Displays the form error to humans.
I love the GDS' guidance on writing errors here
@see <https://design-system.service.gov.uk/components/error-message/#be-clear-and-concise>
-}
viewError : Error -> Html msg
viewError error =
    let
        headingId =
            "addEntryFrom-error-heading"

        errorExplanation =
            case error of
                GeolocationError Geo.PermissionDenied ->
                    text "We do not have permission to read your location. Perhaps there is a setting in your browser, a pop-up window, or your phone's top menu? For now, you can save the note without a location, using the checkbox below."

                GeolocationError Geo.PositionUnavailable ->
                    text "We could not acquire your location. For now, you can save the note without a location, using the checkbox below."

                GeolocationError Geo.Timeout ->
                    text "It took us to long to acquire your location. This can happen sometimes. For now, you can save the note without a location, using the checkbox below."

                -- NOTE: for requestError, there are three main cases:
                --  - QuotaExceeded (the important one)
                --  - UnaccountedError (we messed up somewhere, probably)
                --  - Any other RequestError variant (either internal, or a version mismatch, but I don't know if either is actionable)
                SavingError requestError ->
                    let
                        internalError =
                            text "We could not save the note locally, because of an internal error. It could be temporary, so you can try again later. If the error persists, please get in touch."
                    in
                    case requestError of
                        Store.QuotaExceededError ->
                            -- TODO: Link to entries page here
                            div [ class "vs3" ]
                                [ paragraph [] [ text "We could not save the note locally, because the storage space allocated to this application has run out. This can happen if your device is low on free space." ]
                                , paragraph [] [ text "There are two common options to solve this: " ]
                                , ul [ class "vs2 pl4" ]
                                    [ li [] [ text "Free up space on your device." ]
                                    , li []
                                        [ a [ href "/data", class "near-black" ] [ text "Export your entries" ]
                                        , text " and then clear the site data."
                                        ]
                                    ]
                                , paragraph []
                                    [ text "The "
                                    , a [ href "/data", class "near-black" ] [ text "Data page" ]
                                    , text " has more guidance on data usage and export options."
                                    ]
                                ]

                        Store.InvalidStateError ->
                            text "It is impossible to write to the local store. This is likely the browser not providing access to write. This can happen in some Private Mode sessions. If this error persists, please get in touch."

                        Store.UnaccountedError ->
                            text "We could not save the location locally, because of an unexpected error. This is possibly an error in the code. Please get in touch if you run into this!"

                        Store.UnknownError ->
                            internalError

                        Store.VersionError ->
                            internalError

                        Store.AbortError ->
                            internalError

                        Store.ConstraintError ->
                            internalError
    in
    div
        [ HA.tabindex -1
        , HA.id errorSummaryId
        , HA.attribute "role" "group"
        , HA.attribute "aria-labelledby" headingId
        , class "vs2 pa3 bg-washed-red near-black ba bw1 br2 b--light-red focus-shadow-faint"
        ]
        [ subSubHeading 3 [ HA.id headingId ] [ text "There is a problem" ]
        , paragraph [] [ errorExplanation ]
        ]
