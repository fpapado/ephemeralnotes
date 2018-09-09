port module Entry exposing (Entry, EntryId)

import Html exposing (Html)
import Location
import Json.Decode as D
import Json.Encode as E
import Time



-- CUSTOM TYPES


type alias Entry 
    { id : EntryId
    , front : String
    , back : String
    , time : Time.Posix
    , timeZone : Time.Zone
    , location : Location.Location
    , schemaVersion : SchemaVersion
    }

DecodeEntry : SchemaVersion -> Decoder Entry

-- TODO: try different versions

type EntryId
    = EntryId String



-- TODO: consider using the JSON decode failure type


type ToElm
    = -- An update is available to the app
      UpdateAvailable
    | BeforeInstallPrompt
    | DecodingError D.Error


type FromElm
    = -- The user has accepted the update
      UpdateAccepted
      -- The user has postponed the update
    | UpdateDefered
    | InstallPromptAccepted
    | InstallPromptDefered



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> swFromElm


acceptUpdate : Cmd msg
acceptUpdate =
    send UpdateAccepted


deferUpdate : Cmd msg
deferUpdate =
    send UpdateDefered


acceptInstallPrompt : Cmd msg
acceptInstallPrompt =
    send InstallPromptAccepted


deferInstallPrompt : Cmd msg
deferInstallPrompt =
    send InstallPromptDefered



--IN


sub : Sub ToElm
sub =
    D.decodeValue decodeToElm
        |> swToElm
        |> Sub.map (extract DecodingError)



-- PORTS


port swFromElm : E.Value -> Cmd msg


port swToElm : (D.Value -> msg) -> Sub msg




-- JSON


decodeToElm : D.Decoder ToElm
decodeToElm =
    D.field "tag" D.string
        |> D.andThen decodeToElmInner


decodeToElmInner : String -> D.Decoder ToElm
decodeToElmInner tag =
    case tag of
        "UpdateAvailable" ->
            D.succeed UpdateAvailable

        "BeforeInstallPrompt" ->
            D.succeed BeforeInstallPrompt

        _ ->
            D.fail ("Unknown message" ++ tag)


encodeFromElm : FromElm -> E.Value
encodeFromElm data =
    case data of
        UpdateAccepted ->
            E.object
                [ ( "tag", E.string "UpdateAccepted" )
                , ( "data", E.object [] )
                ]

        UpdateDefered ->
            E.object
                [ ( "tag", E.string "UpdateDefered" )
                , ( "data", E.object [] )
                ]

        InstallPromptAccepted ->
            E.object
                [ ( "tag", E.string "InstallPromptAccepted" )
                , ( "data", E.object [] )
                ]

        InstallPromptDefered ->
            E.object
                [ ( "tag", E.string "InstallPromptDefered" )
                , ( "data", E.object [] )
                ]



-- UTILS


{-| Turn a `Result e a` to an `a`, by applying the conversion
function specified to the `e`.
-}
extract : (e -> a) -> Result e a -> a
extract f x =
    case x of
        Ok a ->
            a

        Err e ->
            f e
