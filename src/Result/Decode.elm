module Result.Decode exposing (decoder)

import Json.Decode as JD exposing (Decoder)
import Result exposing (Result)


{-| Decode a custom Result from a standard JSON representation
-}
decoder : Decoder error -> Decoder value -> Decoder (Result error value)
decoder errorDecoder valueDecoder =
    JD.field "tag" JD.string
        |> JD.andThen (decoderOnTag errorDecoder valueDecoder)


decoderOnTag : Decoder error -> Decoder value -> String -> Decoder (Result error value)
decoderOnTag errorDecoder valueDecoder tag =
    case tag of
        "Ok" ->
            okDecoder valueDecoder
                |> JD.map Result.Ok

        "Err" ->
            errDecoder errorDecoder
                |> JD.map Result.Err

        _ ->
            JD.fail ("Unknown tag " ++ tag)


okDecoder : Decoder value -> Decoder value
okDecoder providedDecoder =
    JD.field "data" providedDecoder


errDecoder : Decoder error -> Decoder error
errDecoder providedDecoder =
    JD.field "data" providedDecoder
