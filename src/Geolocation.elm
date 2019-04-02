port module Geolocation exposing
    ( Error(..)
    , Geolocation
    , LocationResult
    , ToElm(..)
    , errorToString
    , getLocation
    , sub
    )

import Html exposing (Html)
import Json.Decode as D
import Json.Encode as E
import Location exposing (LatLon)



-- CUSTOM TYPES


type alias Geolocation =
    LatLon


type alias OutsideData =
    { tag : String, data : E.Value }


type ToElm
    = -- An update is available to the app
      GotLocation LocationResult
    | DecodingError D.Error


type alias LocationResult =
    Result Error LatLon


type FromElm
    = GetLocation



-- Error


type Error
    = PermissionDenied
    | PositionUnavailable
    | Timeout


errorToString : Error -> String
errorToString err =
    case err of
        PermissionDenied ->
            "Permission denied"

        PositionUnavailable ->
            "Position unavailable"

        Timeout ->
            "Geolocation timed out"



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> geolocationFromElm


getLocation : Cmd msg
getLocation =
    send GetLocation



--IN


sub : Sub ToElm
sub =
    D.decodeValue toElmDecoder
        |> geolocationToElm
        |> Sub.map (extract DecodingError)



-- PORTS


port geolocationFromElm : E.Value -> Cmd msg


port geolocationToElm : (D.Value -> msg) -> Sub msg



-- JSON


{-|

    @example
    D.decodeValue decodeToElm {tag: "GotLocation", data: {tag: Ok, data: {lat: 0.15, lon: 12.3}}}
    D.decodeValue decodeToElm {tag: "GotLocation", data: {tag: Err, data: "LocationUnavailable"}}

-}
toElmDecoder : D.Decoder ToElm
toElmDecoder =
    D.field "tag" D.string
        |> D.andThen toElmInnerDecoder


toElmInnerDecoder : String -> D.Decoder ToElm
toElmInnerDecoder tag =
    case tag of
        "GotLocation" ->
            D.field "data" gotLocationDecoder

        _ ->
            D.fail ("Unknown message" ++ tag)


gotLocationDecoder =
    -- TODO:  write a more general decodeResult that does the Ok/Err/_ dance
    D.field "tag" D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "Ok" ->
                        D.field "data" Location.decoder
                            |> D.map (GotLocation << Ok)

                    "Err" ->
                        D.field "data" gotLocationErrDecoder

                    _ ->
                        D.fail ("Unknown result type" ++ tag)
            )


gotLocationErrDecoder =
    D.field "tag" D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "PermissionDenied" ->
                        D.succeed (GotLocation <| Err PermissionDenied)

                    "PositionUnavailable" ->
                        D.succeed (GotLocation <| Err PositionUnavailable)

                    "Timeout" ->
                        D.succeed (GotLocation <| Err Timeout)

                    _ ->
                        D.fail ("Unknown error reason: " ++ tag)
            )


encodeFromElm : FromElm -> E.Value
encodeFromElm data =
    case data of
        GetLocation ->
            E.object
                [ ( "tag", E.string "GetLocation" )
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
