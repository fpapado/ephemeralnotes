port module ServiceWorker exposing (FromElm, ToElm(..), Update(..), send, sub)

import Json.Decode as D
import Json.Encode as E


{-| Module that handles ServiceWorker interactions.
The ServiceWorker API involves asynchronous messaging
via `postMessage`, which makes it particularly suited
for ports.
-}



-- CUSTOM TYPES


type alias OutsideData =
    { tag : String, data : E.Value }



-- TODO: consider using the JSON decode failure type


type ToElm
    = -- An update is available to the app
      UpdateAvailable
    | DecodingError D.Error


type Update
    = None
    | Available
    | Accepted
    | Rejected


type FromElm
    = -- The user has accepted the update
      UpdateAccepted



-- TODO: Consider exposing these more granularly, so we don't have to
-- expose the type constructor at all


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> swFromElm


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
