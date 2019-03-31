port module Store exposing
    ( ToElm(..)
    , getEntries
    , storeEntry
    , sub
    )

import Entry.Entry as Entry exposing (Entry)
import Json.Decode as JD
import Json.Encode as JE


type ToElm
    = GotEntries (List Entry)
    | DecodingError JD.Error


type FromElm
    = StoreEntry Entry
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


storeEntry : Entry -> Cmd msg
storeEntry entry =
    send (StoreEntry entry)



--IN


sub : Sub ToElm
sub =
    JD.decodeValue toElmDecoder
        |> storeToElm
        |> Sub.map (extractResult DecodingError)



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
                , ( "data", Entry.encode entry )
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

        _ ->
            JD.fail ("Unknown message" ++ tag)



-- UTILS


{-| Turn a `Result e a` to an `a`, by applying the conversion
function specified to the `e`.
-}
extractResult : (e -> a) -> Result e a -> a
extractResult f x =
    case x of
        Ok a ->
            a

        Err e ->
            f e
