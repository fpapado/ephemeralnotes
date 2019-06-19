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
    | Validating String
    | ValidationError JD.Error
    | Saving (List Entry)
    | SavingError
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
    | ValidationStarted String
      -- | SaveEntries (List Entry)
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
            ( { model | uploadData = Validating fileContents }
              -- Queue a task on the spot, for the validation
              -- NOTE: This feels a bit hacky because we could do all the uploading + validating + saving
              -- in one go, with sync functions + task chaining.
              -- However, we *want* to yield to the model, and render, so that
              -- we can update the user on the status of each step. For example,
              -- did the pipeline fail because the file was wrong or because they don't have enough space on their device?
              -- You could argue, though, that we can still do that in the pipeline case,
              -- but without being able to communicate every step.
              -- Perhaps that is fine? Perhaps it is less complexity than adding 4 extra states
              -- and a few messages? Let's find out!
            , Task.perform identity (Task.succeed (ValidationStarted fileContents))
            )

        ValidationStarted fileContents ->
            let
                entries =
                    JD.decodeString (JD.list Entry.decoder) fileContents

                ( uploadData, nextCmd ) =
                    case entries of
                        Result.Ok entryList ->
                            ( Saving entryList, Cmd.none )

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
                Validating fileContents ->
                    div []
                        [ paragraph [] [ text "Validating" ]
                        ]

                Saving entries ->
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

                ValidationError error ->
                    div
                        [ class "vs3 pa3 bg-washed-red ba bw1 br2" ]
                        [ paragraph [ class "dark-red" ]
                            [ span [ class "v-mid" ]
                                [ text "We could not import the file you specified, because its contents are different than what we expected. You can find the details below."
                                ]
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
