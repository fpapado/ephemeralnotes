module Entry.Entry exposing (Entry, decode, encode)

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



-- JSON


decode : D.Decoder Entry
decode =
    D.field "schema_version" D.string
        |> D.andThen decodeOnSchema


decodeOnSchema : String -> D.Decoder Entry
decodeOnSchema version =
    case version of
        "1" ->
            D.map V1 decodeV1

        _ ->
            D.fail ("Unknown schema version: " ++ version)


decodeV1 : D.Decoder EntryV1
decodeV1 =
    D.map5 EntryV1
        (D.field "id" Entry.Id.decode)
        (D.field "front" D.string)
        (D.field "back" D.string)
        (D.field "time" D.int |> D.map Time.millisToPosix)
        (D.field "location" Location.decode)


{-| Encode an entry with a schema into the appropriate JSON representation.

import Time
import Location
import Entry.Id
import Json.Decode as D

-- TODO: figure out a null location
e : Entry
e =
{ id = Entry.Id.generate
, front = "Hello"
, back = "World"
, time = Time.millisToPosix 1234567
, location = { lat = Location.latFromFloat 64, lon = Location.lonFromFloat 32 }
}

(D.decodeValue decode (encode e)) --> Ok e

-}
encode : Entry -> E.Value
encode entry =
    case entry of
        V1 e ->
            E.object
                [ ( "schema_version", E.string "v1" )
                , ( "front", E.string e.front )
                , ( "back", E.string e.back )
                , ( "time", E.int (Time.posixToMillis e.time) )
                , ( "location", Location.encode e.location )
                ]
