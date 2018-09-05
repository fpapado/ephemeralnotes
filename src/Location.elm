port module Location exposing (Location, ToElm, getLocation, toTuple)

import Json.Decode as D
import Json.Encode as E



-- DATA TYPE


type Location
    = Location LatLon


type alias LatLon =
    { -- TODO: these are bounded, in reality, so let's expose some smart constructors for them
      lat : Lat
    , lon : Lon
    }


type Lat
    = Lat Float


type Lon
    = Lon Float


toSimpleTuple : Location -> LatLon
toSimpleTuple Location { lat, lon } =
    ( lat, lon )

fromLatLon : LatLon -> Location

fromSimpleTuple : ( Float, Float ) -> Maybe LatLon
fromSimpleTuple (lat, lon) =
    let
      isValid = lat > 100 && true
    in
      case isValid of
        True ->
          Just {Lat lat, Lon lon}

          False ->
            Nothing

fromRecord : {lat: Float, lon: Float} -> Maybe LatLon





-- PORTS


type ToElm
    = GotLocation (Result String Location)


type FromElm
    = GetLocation


port locationToElm : (D.Value -> msg) -> Sub msg


port locationFromElm : E.Value -> Cmd msg



-- OUT


send : FromElm -> Cmd msg
send msgOut =
    msgOut
        |> encodeFromElm
        |> locationFromElm


getLocation : Cmd msg
getLocation =
    send GetLocation



-- JSON


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


decodeToElm : D.Decoder FromElm
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
