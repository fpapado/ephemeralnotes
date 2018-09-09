module Location exposing
    ( LatLon
    , decode
    , decodeLat
    , decodeLon
    , encode
    , latFromFloat
    , latToFloat
    , lonFromFloat
    , lonToFloat
    )

import Json.Decode as D
import Json.Encode as E



-- DATA TYPES


{-| Decimal degrees and Plus/minus—Latitude and longitude coordinates are
represented as decimal numbers. The latitude is preceded by a minus
sign ( – ) if it is south of the equator (a positive number implies north),
and the longitude is preceded by a minus sign if it is west of the prime
meridian (a positive number implies east); for example, 37.68455° –97.34110°
@see: <https://msdn.microsoft.com/en-us/library/aa578799.aspx>
-}
type alias LatLon =
    { lat : Latitude, lon : Longitude }


{-| Latitude measures how far north or south of the equator a place is located.
The equator is situated at 0°, the North Pole at 90° north (or 90°, because
a positive latitude implies north), and the South Pole at 90° south (or –90°).
Latitude measurements range from 0° to (+/–)90°.
-}
type Latitude
    = Latitude Float


{-| Latitude measurements range from 0° to (+/–)90°.
-}
latFromFloat : Float -> Maybe Latitude
latFromFloat f =
    case f >= -90 && f <= 90 of
        True ->
            Just (Latitude f)

        False ->
            Nothing


latToFloat : Latitude -> Float
latToFloat (Latitude f) =
    f


{-| Longitude measures how far east or west of the prime meridian a place is located.
The prime meridian runs through Greenwich, England.
Longitude measurements range from 0° to (+/–)180°.
-}
type Longitude
    = Longitude Float


{-| Longitude measurements range from 0° to (+/–)180°.
-}
lonFromFloat : Float -> Maybe Longitude
lonFromFloat f =
    case f >= -180 && f <= 180 of
        True ->
            Just (Longitude f)

        False ->
            Nothing


lonToFloat : Longitude -> Float
lonToFloat (Longitude f) =
    f



-- JSON


encode : LatLon -> E.Value
encode { lat, lon } =
    E.object
        [ ( "lat", E.float <| latToFloat lat )
        , ( "lon", E.float <| lonToFloat lon )
        ]


{-| Decode an object of shape {lat, lon} to LatLon/Location
-}
decode : D.Decoder LatLon
decode =
    D.map2 LatLon
        (D.field "lat" decodeLat)
        (D.field "lon" decodeLon)


{-| Decode a generic Float to a Latitude, or fail
-}
decodeLat : D.Decoder Latitude
decodeLat =
    D.map latFromFloat D.float
        |> D.andThen (failIfMaybe "Latitude could not be decoded")


{-| Decode a generic Float to a Longitude, or fail
-}
decodeLon : D.Decoder Longitude
decodeLon =
    D.map lonFromFloat D.float
        |> D.andThen (failIfMaybe "Longitude could not be decoded")


{-| Utility that fails the decoding with a message if the value is maybe
-}
failIfMaybe : String -> Maybe a -> D.Decoder a
failIfMaybe err m =
    case m of
        Just a ->
            D.succeed a

        Nothing ->
            D.fail err



-- MATH
-- TODO: sort, nearest, list functions etc
