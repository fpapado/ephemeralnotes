port module Geolocation exposing
    ( ToElm(..)
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
      GotLocation (Result Error LatLon)
    | DecodingError D.Error


type Error
    = PermissionDenied
    | LocationUnavailable
    | Timeout


type FromElm
    = GetLocation



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
    D.decodeValue decodeToElm
        |> geolocationToElm
        |> Sub.map (extract DecodingError)



-- PORTS


port geolocationFromElm : E.Value -> Cmd msg


port geolocationToElm : (D.Value -> msg) -> Sub msg



-- JSON


{-|

    @example
    D.decodeValue decodeToElm {tag: "GotLocation", res: {tag: Ok, data: {lat: 0.15, lon: 12.3}}}
    D.decodeValue decodeToElm {tag: "GotLocation", res: {tag: Err, error: "LocationUnavailable"}}

-}
decodeToElm : D.Decoder ToElm
decodeToElm =
    D.field "tag" D.string
        |> D.andThen decodeToElmInner


decodeToElmInner : String -> D.Decoder ToElm
decodeToElmInner tag =
    case tag of
        "GotLocation" ->
            D.field "res" decodeGotLocation

        _ ->
            D.fail ("Unknown message" ++ tag)


decodeGotLocation =
    -- TODO:  write a more general decodeResult that does the Ok/Err/_ dance
    D.field "tag" D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "Ok" ->
                        D.field "data" Location.decode
                            |> D.map (GotLocation << Ok)

                    "Err" ->
                        D.field "error" D.string
                            |> D.andThen decodeGotLocationErr

                    _ ->
                        D.fail ("Unknown result type" ++ tag)
            )


decodeGotLocationErr err =
    case err of
        "PermissionDenied" ->
            D.succeed (GotLocation <| Err PermissionDenied)

        "LocationUnavailable" ->
            D.succeed (GotLocation <| Err LocationUnavailable)

        "Timeout" ->
            D.succeed (GotLocation <| Err Timeout)

        _ ->
            D.fail ("Unknown error reason" ++ err)


encodeFromElm : FromElm -> E.Value
encodeFromElm data =
    case data of
        GetLocation ->
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
