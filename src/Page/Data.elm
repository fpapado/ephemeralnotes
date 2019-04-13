module Page.Data exposing (Model, Msg, init, update, view)

import Entry.Entry as Entry exposing (Entry)
import File.Download
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import Json.Encode as JE
import RemoteData exposing (RemoteData)
import String.Transforms
import Task exposing (Task)
import Time
import Ui exposing (..)



-- MODEL


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


type alias Context =
    { entries : EntryData
    }


type alias EntryData =
    RemoteData String (List Entry)



-- UPDATE


type Msg
    = ClickedDownload (List Entry)
    | GotDownloadTime (List Entry) Time.Posix
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Import/Export
        ClickedDownload entries ->
            -- Get the time, then save
            ( model, Task.perform (GotDownloadTime entries) Time.now )

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
            , File.Download.string filename "application/json" entriesJson
            )

        NoOp ->
            ( model, Cmd.none )



-- VIEW


view : Context -> { title : String, content : Html Msg }
view { entries } =
    { title = "Data"
    , content = viewContent entries
    }


viewContent : EntryData -> Html Msg
viewContent entryData =
    div []
        [ centeredContainer
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3 vs4-ns" ]
                    [ heading 1 [] [ text "Data" ]
                    , section [ class "vs3 vs4-ns" ]
                        [ subHeading 2 [] [ text "Download" ]
                        , viewImportExport entryData
                        ]
                    ]
                ]
            ]
        ]



-- TODO: Handle the loading state for the download here


viewImportExport : EntryData -> Html Msg
viewImportExport entryData =
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
