port module Store exposing
    ( RequestError(..)
    , ToElm(..)
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
    | GotBatchImportedEntries (Result RequestError Int)
    | GotEntry (Result String Entry)
    | BadMessage JD.Error



-- @see https://developer.mozilla.org/en-US/docs/Web/API/IDBRequest/error


type RequestError
    = -- If you abort the transaction, then all requests still in progress receive this error.
      AbortError
      -- If you insert data that doesn't conform to a constraint.
      -- It's an exception type for creating stores and indexes.
      -- You get this error, for example, if you try to add a new key
      -- that already exists in the record.
    | ConstraintError
      -- If you run out of disk quota and the user declined to grant you more space.
    | QuotaExceededError
      -- If the operation failed for reasons unrelated to the database itself.
      -- A failure due to disk IO errors is such an example.
    | UnknownError
      -- If you try to open a database with a version lower than the one it already has.
    | VersionError
      -- An error we (as developers) have not accounted for.
      -- Possibly, the propagation of errors failed and we ended up wihout err.name.
    | UnaccountedError


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

        "GotBatchImportedEntries" ->
            -- @example {tag: "GotBatchImportedEntries", data: {tag: "Err", data: "UnknownError"}}
            JD.field "data"
                (JD.field "tag" JD.string
                    |> JD.andThen
                        (\tag_ ->
                            -- TODO: Write a more generic Result encoder/decoder
                            case tag_ of
                                "Err" ->
                                    JD.field "data" (JD.string |> JD.andThen requestErrorDecoder)
                                        |> JD.map (GotBatchImportedEntries << Err)

                                "Ok" ->
                                    JD.field "data" JD.int
                                        |> JD.map (GotBatchImportedEntries << Ok)

                                _ ->
                                    JD.fail ("Unknown tag when decoding result: " ++ tag_)
                        )
                )

        "GotEntry" ->
            -- GotEntry is a Result String Entry, so use the custom Result Decoder!
            JD.field "data" (Result.Decode.decoder JD.string Entry.decoder)
                |> JD.map GotEntry

        _ ->
            JD.fail ("Unknown message: " ++ tag)


requestErrorDecoder : String -> JD.Decoder RequestError
requestErrorDecoder tag =
    case tag of
        "AbortError" ->
            JD.succeed AbortError

        "ConstraintError" ->
            JD.succeed ConstraintError

        "QuotaExceededError" ->
            JD.succeed QuotaExceededError

        "UnknownError" ->
            JD.succeed UnknownError

        "VersionError" ->
            JD.succeed VersionError

        "UnaccountedError" ->
            JD.succeed UnaccountedError

        _ ->
            JD.fail ("Unknown requestError: " ++ tag)
