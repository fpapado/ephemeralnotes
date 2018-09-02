port module ServiceWorker exposing
    ( SwUpdate
    , ToElm(..)
    , acceptUpdate
    , deferUpdate
    , send
    , sub
    , updateAccepted
    , updateAvailable
    , updateDefered
    , updateNone
    , viewSwUpdate
    )

import Html exposing (Html)
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


type FromElm
    = -- The user has accepted the update
      UpdateAccepted
      -- The user has postponed the update
    | UpdateDefered



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



--IN


sub : Sub ToElm
sub =
    D.decodeValue decodeToElm
        |> swToElm
        |> Sub.map (extract DecodingError)



-- PORTS


port swFromElm : E.Value -> Cmd msg


port swToElm : (D.Value -> msg) -> Sub msg



-- SW UPDATE


type SwUpdate
    = None
    | Available
    | Accepted
    | Defered


updateNone =
    None


updateAvailable =
    Available


updateAccepted =
    Accepted


updateDefered =
    Defered


{-| View function that accepts a separate view for each update state.
Exhaustive and does not expose the SwUpdate constructor.
-}
viewSwUpdate : SwUpdate -> { none : Html msg, available : Html msg, accepted : Html msg, defered : Html msg } -> Html msg
viewSwUpdate swUpdate { none, available, accepted, defered } =
    case swUpdate of
        None ->
            none

        Available ->
            available

        Accepted ->
            accepted

        Defered ->
            defered



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

        UpdateDefered ->
            E.object
                [ ( "tag", E.string "UpdateDefered" )
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
