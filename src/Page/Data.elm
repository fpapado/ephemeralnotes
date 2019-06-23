module Page.Data exposing (Model, Msg, init, subscriptions, update, view)

import Entry.Entry as Entry exposing (Entry)
import File exposing (File)
import File.Download
import File.Select
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
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
-- TODO: Can any of these things fail granularly?


type UploadData
    = NotAsked
    | Selecting
    | ValidationError JD.Error
    | Saving (List Entry)
      -- TODO: Use Store.RequestError here
    | SavingError String
    | SavingSuccess (List Entry)


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
            case storeMsg of
                -- TODO: Need to associate a message id here, otherwise the initial load while on /data appears to be an import success :D
                Store.GotBatchImportedEntries res ->
                    case res of
                        Ok entries ->
                            ( { model | uploadData = SavingSuccess entries }, Cmd.none )

                        Err err ->
                            ( { model | uploadData = SavingError "We could not store the entries" }, Cmd.none )

                -- Ignore any other msg from the store
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
                                [ text "We could not import the file you specified, because its contents are different than what we expected. You can find the details below."
                                ]
                            ]
                        ]

                SavingError error ->
                    div
                        [ class "vs3 pa3 bg-washed-red ba bw1 br2" ]
                        [ paragraph [ class "dark-red" ]
                            [ span [ class "v-mid" ]
                                [ text "We could not save the entries: "
                                , text error
                                ]
                            ]
                        ]

                SavingSuccess entries ->
                    div [ class "vs3 pa3 bg-washed-green ba bw1 br2" ]
                        [ paragraph [ class "dark-green" ]
                            [ span [ class "v-mid mr2" ] [ Feather.checkCircle Feather.Decorative ]
                            , span [ class "v-mid" ]
                                [ text "Successfully imported "
                                , b [] [ text (String.fromInt (List.length entries) ++ " items!") ]
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

        -- NOTE: We keep the details of the upload error out of the live region, to avoid verbose announcements
        , div []
            [ case uploadData of
                ValidationError error ->
                    pre
                        []
                        [ text <| JD.errorToString error ]

                _ ->
                    text ""
            ]
        ]
