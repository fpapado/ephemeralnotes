module Page.Map exposing (view)

import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Html exposing (..)
import Html.Attributes as HA exposing (class, href)
import Html.Events as HE exposing (onClick)
import Html.Keyed as Keyed
import Location as L
import RemoteData exposing (RemoteData)
import Ui exposing (centeredContainerWide, heading, paragraph)


type alias Context =
    { entries : EntryData
    }


type alias EntryData =
    RemoteData String (List Entry)


view : Context -> { title : String, content : Html msg }
view context =
    { title = "Map"
    , content = viewContent context
    }


viewContent : Context -> Html msg
viewContent { entries } =
    div []
        [ centeredContainerWide
            []
            [ div [ class "vs4 vs5-ns" ]
                [ div [ class "vs3 vs4-ns" ]
                    [ heading 1 [] [ text "Map" ]
                    , viewMap entries
                    ]
                ]
            ]
        ]


viewMap : EntryData -> Html msg
viewMap entryData =
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
    div [ class "leaflet-map-wrapper" ]
        [ Keyed.node "leaflet-map"
            [ HA.attribute "latitude" "60.1699"
            , HA.attribute "longitude" "24.9384"
            , HA.attribute "zoom" "12"
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
