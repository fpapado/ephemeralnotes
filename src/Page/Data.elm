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
    }


type alias EntryData =
    RemoteData String (List Entry)


jsonMime =
    "application/json"



-- UPDATE


type Msg
    = ClickedDownload (List Entry)
    | GotDownloadTime (List Entry) Time.Posix
    | FileUploadRequested
    | FileSelected File
    | FileLoaded String
    | FromStore Store.ToElm
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

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Context -> Model -> { title : String, content : Html Msg }
view { entries } model =
    { title = "Data"
    , content = viewContent entries model
    }


multiStyles : List ( String, String ) -> List (Html.Attribute msg)
multiStyles styles =
    styles
        |> List.map (\( name, value ) -> HA.style name value)


viewContent : EntryData -> Model -> Html Msg
viewContent entryData model =
    div []
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3" ]
                    [ heading 1 [] [ text "Data" ]
                    , section [ class "vs3" ]
                        [ subHeading 2 [] [ text "Export" ]
                        , viewExport entryData
                        ]
                    , section [ class "vs3" ]
                        [ subHeading 2 [] [ text "Import" ]
                        , viewImport
                        , viewUploadData model.uploadData
                        ]
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
                , paragraph
                    [ class "measure" ]
                    [ text "The file will be downloaded in the JSON format. You can use this file to process your data in different ways, such as creating flash cards. In the future, you can use this file to import data into this application on another device." ]
                ]

            _ ->
                [ styledButtonBlue True
                    [ onClick <| NoOp ]
                    [ text "Download Entries" ]
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
                        [ class "vs3 pa3 bg-washed-red ba bw1 br2" ]
                        [ paragraph [ class "dark-red" ]
                            [ span [ class "v-mid" ]
                                [ text "We could not import the file you specified, because its contents are different than what we expected. It might be possible to fix this by following the errors below and editing the file manually."
                                ]
                            ]
                        ]

                SavingError error ->
                    div
                        [ class "vs3 pa3 bg-washed-red ba bw1 br2" ]
                        [ paragraph [ class "dark-red" ]
                            [ span [ class "v-mid" ]
                                [ text (HumanError.toString (humanRequestError error))
                                ]
                            ]
                        ]

                SavingSuccess entries ->
                    div [ class "vs3 pa3 bg-washed-green ba bw1 br2" ]
                        [ paragraph [ class "dark-green" ]
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
        , div [ class "ph3 pv2 bg-white ba bw1 br2" ]
            [ case uploadData of
                ValidationError error ->
                    pre
                        [ class "pre overflow-x-auto" ]
                        [ text <| JD.errorToString error ]

                _ ->
                    text ""
            ]
        ]


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
