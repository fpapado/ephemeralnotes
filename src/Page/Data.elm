module Page.Data exposing (Model, Msg, init, subscriptions, update, view)

import Entry.Entry as Entry exposing (Entry)
import File exposing (File)
import File.Download
import File.Select
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import HumanError exposing (HumanError)
import Json.Decode as JD
import Json.Encode as JE
import RemoteData exposing (RemoteData)
import Route
import Store
import Store.Persistence as Persistence exposing (Persistence)
import String.Transforms
import Svg.Feather as Feather
import Task exposing (Task)
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    { uploadData : UploadData
    }



-- Custom type that models the various states of uploading and importing data


type UploadData
    = NotAsked
    | Selecting
    | ValidationError JD.Error
    | Saving (List Entry)
    | SavingError Store.RequestError
    | SavingSuccess Int


init : ( Model, Cmd Msg )
init =
    ( { uploadData = NotAsked
      }
    , Cmd.none
    )


type alias Context =
    { entries : EntryData
    , persistence : Maybe Persistence
    }


type alias EntryData =
    RemoteData Store.RequestError (List Entry)


jsonMime =
    "application/json"



-- UPDATE


type Msg
    = -- Export
      ClickedDownload (List Entry)
    | GotDownloadTime (List Entry) Time.Posix
      -- Import
    | FileUploadRequested
    | FileSelected File
    | FileLoaded String
      -- Subscription to store (for Import)
    | FromStore Store.ToElm
      --
    | RequestedPersistence
    | NoOp



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map FromStore Store.sub
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Import/Export
        ClickedDownload entries ->
            -- Get the time, then save
            ( model, Task.perform (GotDownloadTime entries) Time.now )

        FileUploadRequested ->
            ( model, requestFile )

        FileSelected file ->
            ( model, Task.perform FileLoaded (File.toString file) )

        FileLoaded fileContents ->
            -- We have loaded the file, and we must now validate it
            -- If invalid, fail with a decodingError
            -- If valid, send a Cmd to the Store to save the entries
            let
                entriesRes =
                    JD.decodeString (JD.list Entry.decoder) fileContents

                ( uploadData, nextCmd ) =
                    case entriesRes of
                        Result.Ok entries ->
                            ( Saving entries, Store.storeBatchImportedEntries entries )

                        Result.Err decodingError ->
                            ( ValidationError decodingError, Cmd.none )
            in
            ( { model | uploadData = uploadData }, nextCmd )

        GotDownloadTime entries time ->
            let
                entriesJson =
                    entries
                        |> JE.list Entry.encode
                        |> String.Transforms.fromValue

                filename =
                    "entries-" ++ String.fromInt (Time.posixToMillis time) ++ ".json"
            in
            ( model
            , File.Download.string filename jsonMime entriesJson
            )

        -- The import cares about GotEntry
        FromStore storeMsg ->
            -- We only care about the GotBatchImportedEntries if we are waiting for it
            case ( model.uploadData, storeMsg ) of
                ( Saving _, Store.GotBatchImportedEntries res ) ->
                    case res of
                        Ok entries ->
                            ( { model | uploadData = SavingSuccess entries }, Cmd.none )

                        Err err ->
                            ( { model | uploadData = SavingError err }, Cmd.none )

                -- Ignore any other msg from the store, and in any other state
                _ ->
                    ( model, Cmd.none )

        -- TODO: Consider changing a state to RequestingPersistence
        -- TODO: Consider adding a listener for Store.GotPersistence here, to set RequestingPersistence
        RequestedPersistence ->
            ( model, Store.requestPersistence )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Context -> Model -> { title : String, content : Html Msg }
view context model =
    { title = "Data"
    , content = viewContent context model
    }


viewContent : Context -> Model -> Html Msg
viewContent { entries, persistence } model =
    div []
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3" ]
                    [ heading 1 [] [ text "Data" ]
                    , paragraph []
                        [ text "Data is stored locally to your device, in the browser. It is never transmitted to a server or remote location. You can use the utilities below to transfer data between your devices."
                        ]
                    , -- When persistence is Maybe.Nothing, we haven't checked yet / are checking; no need to show anything.
                      Maybe.map viewPersistence persistence
                        |> Maybe.withDefault (text "")
                    ]
                , section [ class "vs3" ]
                    [ subHeading 2 [] [ text "Export" ]
                    , viewExport entries
                    ]
                , section [ class "vs3" ]
                    [ subHeading 2 [] [ text "Import" ]
                    , viewImport
                    , viewUploadData model.uploadData
                    ]
                , section [ class "vs3" ]
                    [ subHeading 2 [] [ text "Usage" ]
                    , viewUsage
                    ]
                ]
            ]
        ]



-- TODO: Handle the loading state for the download here


viewExport : EntryData -> Html Msg
viewExport entryData =
    div [ class "vs3" ]
        (case entryData of
            RemoteData.Success entries ->
                [ styledButtonBlue False
                    [ onClick (ClickedDownload entries) ]
                    [ text "Export Entries" ]
                , details [ class "vs3 f4" ]
                    [ summary []
                        [ text "About the export format" ]
                    , paragraph
                        []
                        [ text "The file will be exported in the JSON format. You can use this file to process your data in different ways, such as creating flash cards. You can also use this file to import data into this application on another device." ]
                    ]
                ]

            _ ->
                [ styledButtonBlue True
                    [ onClick <| NoOp ]
                    [ text "Export Entries" ]
                , paragraph [ class "measure" ] [ text "We have not loaded the entries yet, so we cannot save them." ]
                ]
        )


requestFile : Cmd Msg
requestFile =
    File.Select.file [ jsonMime ] FileSelected


{-|

    Steps when importing:
        - Click upload
        - Select file
        - Separate action to process? Or do we start reading?
        - Try to parse -> Can fail
        - Try to save in db -> can fail?
        - On success? How are we notified? Notify the user of success, and tell them about the entries page.

-}
viewImport : Html Msg
viewImport =
    div [ class "vs3" ] [ styledButtonBlue False [ onClick FileUploadRequested ] [ text "Import" ] ]


viewUploadData : UploadData -> Html msg
viewUploadData uploadData =
    -- NOTE: We set an aria-live region, to announce the import result
    -- We could do this by moving the focus, but there is nothing really actionable there
    div [ class "vs4" ]
        [ div [ HA.attribute "aria-live" "polite" ] <|
            [ case uploadData of
                Saving entries ->
                    div [] [ paragraph [] [ text "Saving..." ] ]

                ValidationError error ->
                    div
                        [ class "vs3 pa3 near-black bg-washed-red ba bw1 br2 b--light-red" ]
                        [ subSubHeading 3 [] [ text "There is a problem" ]
                        , paragraph []
                            [ span [ class "v-mid" ]
                                [ text "We could not import the file you specified, because its contents are different than what we expected. It might be possible to fix this by following the errors below and editing the file manually."
                                ]
                            ]
                        ]

                SavingError error ->
                    div
                        [ class "vs3 pa3 near-black bg-washed-red ba bw1 br2 b--light-red" ]
                        [ subSubHeading 3 [] [ text "There is a problem" ]
                        , paragraph []
                            [ span [ class "v-mid" ]
                                [ text (HumanError.toString (humanRequestError error))
                                ]
                            ]
                        ]

                SavingSuccess entries ->
                    div [ class "vs3 pa3 near-black bg-washed-green ba bw1 br2 b--color-text" ]
                        [ paragraph []
                            [ span [ class "v-mid mr2" ] [ Feather.checkCircle Feather.Decorative ]
                            , span [ class "v-mid" ]
                                [ text "Successfully imported "
                                , b [] [ text <| String.fromInt entries ++ " items!" ]
                                ]
                            ]
                        , paragraph
                            []
                            [ text "You can visit the "
                            , a [ Route.href Route.Home ] [ text "Entries page" ]
                            , text " to find them."
                            ]
                        ]

                _ ->
                    text ""
            ]

        -- NOTE: We keep the details of the ValidationError out of the live region, to avoid verbose announcements
        , case uploadData of
            ValidationError error ->
                div [ class "ph3 pv2 bg-color-bg color-text ba bw1 br2" ]
                    [ pre
                        [ class "pre overflow-x-auto" ]
                        [ text <| JD.errorToString error ]
                    ]

            _ ->
                text ""
        ]


viewUsage : Html msg
viewUsage =
    div [ class "vs3" ]
        [ div [ class "mw6" ] [ Html.node "storage-space" [] [] ]
        , paragraph []
            [ text "The storage limit varies per browser, and also depends on your system's free space. While word entries are quite small, this counter, if available, can give you an indication to export your data."
            ]
        ]



-- UTILS


humanRequestError : Store.RequestError -> HumanError
humanRequestError err =
    case err of
        Store.AbortError ->
            { expectation = HumanError.Expected
            , summary = Just "The import process was aborted, likely because some other error occured."
            , recovery = HumanError.Unrecoverable
            }

        Store.ConstraintError ->
            { expectation = HumanError.Expected
            , summary = Just "We could not complete the import process, because the data being imported seems to conflict with that already stored."
            , recovery = HumanError.Recoverable (HumanError.CustomRecovery "This can happen if you manually edited the data file. Does each entry have an id field?")
            }

        Store.QuotaExceededError ->
            { expectation = HumanError.Expected
            , summary = Just "We could not import the data, because it seems that the application has run out of its allocated space."
            , recovery = HumanError.Recoverable (HumanError.CustomRecovery "You could try freeing up space on your device. If that is not possible, consider exporting your existing data, so you will not lose it. You can then import both files to another device, and continue from there.")
            }

        Store.VersionError ->
            { expectation = HumanError.Expected
            , summary = Just "The import failed because the versions of the data being imported do not match the ones stored."
            , recovery = HumanError.Recoverable (HumanError.CustomRecovery "This might be fixable by closing all tabs that have the application open, and opening it up again.")
            }

        Store.UnknownError ->
            { expectation = HumanError.Expected
            , summary = Just "The import process failed for an unknown reason, and we could not get more details about it."
            , recovery = HumanError.Recoverable HumanError.TryAgain
            }

        Store.UnaccountedError ->
            { expectation = HumanError.Unexpected
            , summary = Just "This is possibly an error in the code. Please get in touch if you run into this!"
            , recovery = HumanError.Unrecoverable
            }


{-| A curated view based on the persistence state. Tries to inform the user of the possiblities.
It is in this module because it is closely related to what we want to communicate,
but you could decide otherwise!
-}
viewPersistence : Persistence -> Html Msg
viewPersistence persistence =
    let
        explanation =
            case persistence of
                Persistence.Unsupported ->
                    "This browser might clear entries, if storage space is running low. It is unlikely, but it could happen. Take care to export your data if your device is low on free space."

                Persistence.Denied ->
                    "The permission to store entries permanently has been denied. The browser might clear them up, if storage space is running low. It is unlikely, but it could happen. Take care to export your data if your device is low on free space."

                Persistence.Failed ->
                    "We could not ensure that entries get stored permanently. This can happen if you only visited the app for the first time recently, and the browser does not trust it yet. Please try again later."

                Persistence.ShouldPrompt ->
                    "This browser might clear entries, if storage space is running low. Please press the button below to give permission to store the entries permanently."

                Persistence.Persisted ->
                    "Entries will get stored permanently in this browser."
    in
    div [ class "vs2" ]
        (case persistence of
            Persistence.Persisted ->
                [ paragraph [ class "status-indicator success" ]
                    [ Feather.checkCircle Feather.Decorative
                    , span [ class "ml2" ] [ text explanation ]
                    ]
                ]

            _ ->
                [ paragraph [ class "status-indicator warning" ]
                    [ Feather.alertCircle Feather.Decorative
                    , span [ class "ml2" ] [ text "Note" ]
                    ]
                , paragraph [] [ text explanation ]
                , case persistence of
                    Persistence.ShouldPrompt ->
                        styledButtonBlue False
                            [ onClick RequestedPersistence ]
                            [ text "Persist data"
                            ]

                    _ ->
                        text ""
                ]
        )
