module Page.Data exposing (Model, Msg, init, update, view)

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
import String.Transforms
import Task exposing (Task)
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    { uploadData : UploadData
    }



-- Upload data can fail if we cannot decode it


type alias UploadData =
    RemoteData JD.Error (List Entry)


init : ( Model, Cmd Msg )
init =
    ( { uploadData = RemoteData.NotAsked
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
    | NoOp


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
            let
                entries =
                    JD.decodeString (JD.list Entry.decoder) fileContents
            in
            ( { model | uploadData = RemoteData.fromResult entries }, Cmd.none )

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

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Context -> Model -> { title : String, content : Html Msg }
view { entries } model =
    { title = "Data"
    , content = viewContent entries model
    }


viewContent : EntryData -> Model -> Html Msg
viewContent entryData model =
    div []
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3 vs4-ns" ]
                    [ heading 1 [] [ text "Data" ]
                    , section [ class "vs3 vs4-ns" ]
                        [ subHeading 2 [] [ text "Export" ]
                        , viewExport entryData
                        ]
                    , section [ class "vs3 vs4-ns" ]
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
                    [ text "Download Entries" ]
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
                RemoteData.Success fileContent ->
                    div [ class "vs3" ]
                        [ paragraph []
                            [ text "Successfully imported "
                            , b [] [ text (String.fromInt (List.length fileContent) ++ " items!") ]
                            ]
                        , paragraph
                            []
                            [ text "You can visit the "
                            , a [ Route.href Route.Home ] [ text "Entries page" ]
                            , text " to find them."
                            ]
                        ]

                RemoteData.Failure jdError ->
                    paragraph [] [ text "We could not import the file you specified, because its format is different than what we expected. You can find the details below." ]

                _ ->
                    text ""
            ]

        -- NOTE: We keep the details of the upload error out of the live region, to avoid verbose announcements
        , div []
            [ case uploadData of
                RemoteData.Failure jdError ->
                    pre
                        []
                        [ text <| JD.errorToString jdError ]

                _ ->
                    text ""
            ]
        ]
