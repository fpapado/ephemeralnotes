port module ServiceWorker exposing
    ( InstallPrompt
    , SwUpdate
    , ToElm(..)
    , acceptInstallPrompt
    , acceptUpdate
    , deferInstallPrompt
    , deferUpdate
    , installPromptAvailable
    , installPromptNone
    , sub
    , updateAccepted
    , updateAvailable
    , updateDeferred
    , updateNone
    , viewInstallPrompt
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
    | BeforeInstallPrompt
    | DecodingError D.Error


type FromElm
    = -- The user has accepted the update
      UpdateAccepted
      -- The user has postponed the update
    | UpdateDeferred
    | InstallPromptAccepted
    | InstallPromptDeferred



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
    send UpdateDeferred


acceptInstallPrompt : Cmd msg
acceptInstallPrompt =
    send InstallPromptAccepted


deferInstallPrompt : Cmd msg
deferInstallPrompt =
    send InstallPromptDeferred



--IN


sub : Sub ToElm
sub =
    D.decodeValue toElmDecoder
        |> swToElm
        |> Sub.map (extractResult DecodingError)



-- PORTS


port swFromElm : E.Value -> Cmd msg


port swToElm : (D.Value -> msg) -> Sub msg



-- SW UPDATE


type SwUpdate
    = None
    | Available
    | Accepted
    | Deferred


updateNone =
    None


updateAvailable =
    Available


updateAccepted =
    Accepted


updateDeferred =
    Deferred


{-| View function that accepts a separate view for each update state.
Exhaustive and does not expose the SwUpdate constructor.
-}
viewSwUpdate : SwUpdate -> { none : Html msg, available : Html msg, accepted : Html msg, deferred : Html msg } -> Html msg
viewSwUpdate swUpdate { none, available, accepted, deferred } =
    case swUpdate of
        None ->
            none

        Available ->
            available

        Accepted ->
            accepted

        Deferred ->
            deferred



-- INSTALL PROMPT


type InstallPrompt
    = NoInstallPrompt
    | InstallPromptAvailable


installPromptNone =
    NoInstallPrompt


installPromptAvailable =
    InstallPromptAvailable


viewInstallPrompt : InstallPrompt -> { none : Html msg, available : Html msg } -> Html msg
viewInstallPrompt installPrompt { none, available } =
    case installPrompt of
        NoInstallPrompt ->
            none

        InstallPromptAvailable ->
            available



-- JSON


toElmDecoder : D.Decoder ToElm
toElmDecoder =
    D.field "tag" D.string
        |> D.andThen toElmInnerDecoder


toElmInnerDecoder : String -> D.Decoder ToElm
toElmInnerDecoder tag =
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

        UpdateDeferred ->
            E.object
                [ ( "tag", E.string "UpdateDeferred" )
                , ( "data", E.object [] )
                ]

        InstallPromptAccepted ->
            E.object
                [ ( "tag", E.string "InstallPromptAccepted" )
                , ( "data", E.object [] )
                ]

        InstallPromptDeferred ->
            E.object
                [ ( "tag", E.string "InstallPromptDeferred" )
                , ( "data", E.object [] )
                ]



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
