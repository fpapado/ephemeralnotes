port module Store exposing
    ( RequestError(..)
    , ToElm(..)
    , checkPersistenceWithoutPrompt
    , getEntries
    , requestPersistence
    , storeBatchImportedEntries
    , storeEntry
    , sub
    )

import Entry.Entry as Entry exposing (Entry, EntryV1Partial)
import Json.Decode as JD
import Json.Encode as JE
import Result.Decode
import Store.Persistence as Persistence exposing (Persistence)


type
    ToElm
    -- TODO: Probably have to associate an ID here, so we know whether GotEntries is in response to init, or a form, or import
    -- TODO: Handle failure case for GotEntries
    = GotEntries (List Entry)
    | GotBatchImportedEntries (Result RequestError Int)
    | GotEntry (Result RequestError Entry)
    | GotPersistence Persistence
    | BadMessage JD.Error


{-| An IndexedDB error
@see <https://developer.mozilla.org/en-US/docs/Web/API/IDBRequest/error>
-}
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
      -- This can happen in the request, if we could not write to the database.
      -- Probably browser related (mainly, that I've seen, Firefox Private Browsing)
    | InvalidStateError
      -- An error we (as developers) have not accounted for.
      -- Possibly, the propagation of errors failed and we ended up wihout err.name.
    | UnaccountedError


type FromElm
    = StoreEntry EntryV1Partial
    | StoreBatchImportedEntries (List Entry)
    | GetEntries
    | CheckPersistenceWithoutPrompt
    | RequestPersistence



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


checkPersistenceWithoutPrompt : Cmd msg
checkPersistenceWithoutPrompt =
    send CheckPersistenceWithoutPrompt


requestPersistence : Cmd msg
requestPersistence =
    send RequestPersistence



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

        CheckPersistenceWithoutPrompt ->
            JE.object
                [ ( "tag", JE.string "CheckPersistenceWithoutPrompt" )
                , ( "data", JE.object [] )
                ]

        RequestPersistence ->
            JE.object
                [ ( "tag", JE.string "RequestPersistence" )
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
                (Result.Decode.decoder
                    (JD.string |> JD.andThen requestErrorDecoder)
                    JD.int
                )
                |> JD.map GotBatchImportedEntries

        "GotEntry" ->
            JD.field "data"
                (Result.Decode.decoder
                    (JD.string |> JD.andThen requestErrorDecoder)
                    Entry.decoder
                )
                |> JD.map GotEntry

        "GotPersistence" ->
            JD.field "data" Persistence.decoder
                |> JD.map GotPersistence

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

        "InvalidStateError" ->
            JD.succeed InvalidStateError

        "UnaccountedError" ->
            JD.succeed UnaccountedError

        _ ->
            JD.fail ("Unknown requestError: " ++ tag)
