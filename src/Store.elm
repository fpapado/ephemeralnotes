port module Store exposing
    ( ToElm(..)
    , getEntries
    , storeBatchImportedEntries
    , storeEntry
    , sub
    )

import Entry.Entry as Entry exposing (Entry, EntryV1Partial)
import Json.Decode as JD
import Json.Encode as JE
import Result.Decode


type
    ToElm
    -- TODO: Intead of unwrapping to DecodingError, make GotEntries Result JD.Error (List Entry)
    -- And then DecodingError would become an explicit UnknownMsg
    -- TODO: Probably have to associate an ID here, so we know whether GotEntries is in response to init, or a form, or import
    = GotEntries (List Entry)
    | GotEntry (Result String Entry)
    | BadMessage JD.Error


type FromElm
    = StoreEntry EntryV1Partial
    | StoreBatchImportedEntries (List Entry)
    | GetEntries



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> storeFromElm


getEntries : Cmd msg
getEntries =
    send GetEntries


storeEntry : EntryV1Partial -> Cmd msg
storeEntry entry =
    send (StoreEntry entry)


storeBatchImportedEntries : List Entry -> Cmd msg
storeBatchImportedEntries entries =
    send (StoreBatchImportedEntries entries)



--IN


sub : Sub ToElm
sub =
    storeToElm (JD.decodeValue toElmDecoder)
        |> Sub.map
            (\subMsg ->
                case subMsg of
                    Ok msg ->
                        msg

                    Err err ->
                        BadMessage err
            )



-- PORTS


port storeFromElm : JE.Value -> Cmd msg


port storeToElm : (JD.Value -> msg) -> Sub msg



-- JSON


encodeFromElm : FromElm -> JE.Value
encodeFromElm data =
    case data of
        StoreEntry entry ->
            JE.object
                [ ( "tag", JE.string "StoreEntry" )
                , ( "data", Entry.encodePartial entry )
                ]

        StoreBatchImportedEntries entries ->
            JE.object
                [ ( "tag", JE.string "StoreBatchImportedEntries" )
                , ( "data", JE.list Entry.encode entries )
                ]

        GetEntries ->
            JE.object
                [ ( "tag", JE.string "GetEntries" )
                , ( "data", JE.object [] )
                ]


toElmDecoder : JD.Decoder ToElm
toElmDecoder =
    JD.field "tag" JD.string
        |> JD.andThen toElmInnerDecoder


toElmInnerDecoder : String -> JD.Decoder ToElm
toElmInnerDecoder tag =
    case tag of
        "GotEntries" ->
            JD.field "data" (JD.list Entry.decoder)
                |> JD.map GotEntries

        "GotEntry" ->
            -- GotEntry is a Result String Entry, so use the custom Result Decoder!
            JD.field "data" (Result.Decode.decoder JD.string Entry.decoder)
                |> JD.map GotEntry

        _ ->
            JD.fail ("Unknown message: " ++ tag)
