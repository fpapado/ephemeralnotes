module Location exposing
    ( LatLon
    , Latitude
    , Longitude
    , decoder
    , encode
    , isNullIsland
    , latDecoder
    , latFromFloat
    , latToFloat
    , lonDecoder
    , lonFromFloat
    , lonToFloat
    , nullIsland
    , toGpsPrecisionString
    )

import Json.Decode as D
import Json.Encode as E
import Round



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


{-| Null island is the location 0, 0, often used as a short-hand for undefined data.
TODO: Consider whether it should be easily constructable or not!
-}
nullIsland : LatLon
nullIsland =
    { lat = Latitude 0, lon = Longitude 0 }


{-| Regardless of whether null island is a good idea, we need some way to spot it,
in case the data we consume provides it
-}
isNullIsland : LatLon -> Bool
isNullIsland { lat, lon } =
    latToFloat lat == 0 && lonToFloat lon == 0



-- fromFloats : {lat: Float, lon: Float} -> Maybe LatLon


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


{-| Turn a float into a longitude value, if valid.
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
decoder : D.Decoder LatLon
decoder =
    D.map2 LatLon
        (D.field "lat" latDecoder)
        (D.field "lon" lonDecoder)


{-| Decode a generic Float to a Latitude, or fail
-}
latDecoder : D.Decoder Latitude
latDecoder =
    D.map latFromFloat D.float
        |> D.andThen (failIfMaybe "Latitude could not be decoded")


{-| Decode a generic Float to a Longitude, or fail
-}
lonDecoder : D.Decoder Longitude
lonDecoder =
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


{-| Get a string representation of a GPS coordinate.
In practice, this means up to 5 digits
@see <https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude>

> The fifth decimal place is worth up to 1.1 m: it distinguish trees from each other.
> Accuracy to this level with commercial GPS units can only be achieved with
> differential correction.

-}
toGpsPrecisionString : LatLon -> String
toGpsPrecisionString { lat, lon } =
    Round.round 5 (latToFloat lat) ++ ", " ++ Round.round 5 (lonToFloat lon)



-- MATH
-- TODO: sort, nearest, list functions etc
