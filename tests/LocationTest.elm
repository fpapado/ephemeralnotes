module LocationTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Location
import Test exposing (..)


suite : Test
suite =
    describe "The Location module"
        [ describe "Latitude constructor"
            [ fuzz Fuzz.float
                "Latitude measurements range from 0° to (+/–)90°"
                (\randomFloat ->
                    randomFloat
                        |> Location.latFromFloat
                        |> getLatitudeExpectation randomFloat
                )
            ]
        , describe "Longitude constructor"
            [ fuzz Fuzz.float
                "Longitude measurements range from 0° to (+/–)180°."
                (\randomFloat ->
                    randomFloat
                        |> Location.lonFromFloat
                        |> getLongitudeExpectation randomFloat
                )
            ]
        ]


{-| Take any random float, and return the expectation (whether it should be valid or not)
-}
getLatitudeExpectation : Float -> Maybe a -> Expectation
getLatitudeExpectation randomFloat =
    case randomFloat >= -90 && randomFloat <= 90 of
        True ->
            Expect.notEqual Nothing

        False ->
            Expect.notEqual Nothing


{-| Take any random float, and return the expectation (whether it should be valid or not)
-}
getLongitudeExpectation : Float -> Maybe a -> Expectation
getLongitudeExpectation randomFloat =
    case randomFloat >= -180 && randomFloat <= 180 of
        True ->
            Expect.notEqual Nothing

        False ->
            Expect.equal Nothing
