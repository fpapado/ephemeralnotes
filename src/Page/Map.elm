module Page.Map exposing (view)

import DarkMode
import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import Location as L
import RemoteData exposing (RemoteData)
import Store
import Ui exposing (centeredContainerWide, heading, paragraph)


type alias Context =
    { entries : EntryData
    , darkMode : DarkMode.Mode
    }


type alias EntryData =
    RemoteData Store.RequestError (List Entry)


view : Context -> { title : String, content : Html msg }
view context =
    { title = "Map"
    , content = viewContent context
    }


viewContent : Context -> Html msg
viewContent { entries, darkMode } =
    centeredContainerWide
        [ class "w-100 flex flex-column flex-grow-1" ]
        [ heading 1 [ class "visually-hidden" ] [ text "Map" ]
        , viewMap [ class "flex flex-column flex-grow-1" ] darkMode entries
        ]


viewMap : List (Html.Attribute msg) -> DarkMode.Mode -> EntryData -> Html msg
viewMap attrs mode entryData =
    let
        markerNodes =
            case entryData of
                RemoteData.NotAsked ->
                    []

                RemoteData.Loading ->
                    []

                RemoteData.Failure err ->
                    []

                RemoteData.Success entries ->
                    List.map viewEntryMarkerKeyed entries
    in
    div (attrs ++ [ class "leaflet-map-wrapper" ])
        [ Keyed.node "leaflet-map"
            [ HA.attribute "defaultZoom" "8"
            , HA.attribute "theme" (String.toLower <| DarkMode.modeToString mode)
            , class "flex flex-column flex-grow-1"
            ]
            markerNodes
        ]


viewEntryMarkerKeyed : Entry -> ( String, Html msg )
viewEntryMarkerKeyed ambiguousEntry =
    case ambiguousEntry of
        Entry.V1 entry ->
            ( Entry.Id.toString entry.id
            , Html.node "leaflet-marker"
                [ HA.attribute "latitude" (String.fromFloat (L.latToFloat entry.location.lat))
                , HA.attribute "longitude" (String.fromFloat (L.lonToFloat entry.location.lon))
                ]
                [ div [ class "vs2" ]
                    [ paragraph [ class "fw6" ] [ text entry.front ]
                    , paragraph [] [ text entry.back ]
                    ]
                ]
            )
