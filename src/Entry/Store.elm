port module Store exposing
    ( ToElm(..)
    ,  getEntries
       -- , gotEntries

    ,  storeEntry
       -- , sub

    )

import Entry.Entry as Entry exposing (Entry)
import Json.Decode as JD
import Json.Encode as JE


type ToElm
    = GotEntries (List Entry)


type FromElm
    = StoreEntry Entry
    | GetEntries



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> swFromElm


getEntries : Cmd msg
getEntries =
    send GetEntries


storeEntry : Entry -> Cmd msg
storeEntry entry =
    send (StoreEntry entry)



-- PORTS


port swFromElm : JE.Value -> Cmd msg


port swToElm : (JD.Value -> msg) -> Sub msg


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
