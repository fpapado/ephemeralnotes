module Entry.Entry exposing (Entry(..), EntryV1Partial, decoder, encode, encodePartial)

import Entry.Id
import Html exposing (Html)
import Json.Decode as D
import Json.Encode as E
import Location
import Time



-- CUSTOM TYPES


{-| Entry is tagged as SchemaVersion RecordForSchema, allowing for versioning
and migrations
-}
type Entry
    = V1 EntryV1


type alias EntryV1 =
    { id : Entry.Id.Id
    , front : String
    , back : String
    , time : Time.Posix
    , location : Location.LatLon
    }


type alias EntryV1Partial =
    { front : String
    , back : String
    , time : Time.Posix
    , location : Location.LatLon
    }


decoder : D.Decoder Entry
decoder =
    D.field "schema_version" D.int
        |> D.andThen schemaDecoder


schemaDecoder : Int -> D.Decoder Entry
schemaDecoder version =
    case version of
        1 ->
            D.map V1 v1Decoder

        _ ->
            D.fail ("Unknown schema version: " ++ String.fromInt version)


v1Decoder : D.Decoder EntryV1
v1Decoder =
    D.map5 EntryV1
        (D.field "id" Entry.Id.decoder)
        (D.field "front" D.string)
        (D.field "back" D.string)
        (D.field "time" D.int |> D.map Time.millisToPosix)
        (D.field "location" Location.decoder)


{-| Encode an entry with a schema into the appropriate JSON representation.
-}
encode : Entry -> E.Value
encode entry =
    case entry of
        V1 e ->
            E.object
                [ ( "schema_version", E.string "v1" )
                , ( "id", E.string (Entry.Id.toString e.id) )
                , ( "front", E.string e.front )
                , ( "back", E.string e.back )
                , ( "time", E.int (Time.posixToMillis e.time) )
                , ( "location", Location.encode e.location )
                ]


{-| Encode an entry with a schema into the appropriate JSON representation.
-}
encodePartial : EntryV1Partial -> E.Value
encodePartial e =
    E.object
        [ ( "front", E.string e.front )
        , ( "back", E.string e.back )
        , ( "time", E.int (Time.posixToMillis e.time) )
        , ( "location", Location.encode e.location )
        ]
