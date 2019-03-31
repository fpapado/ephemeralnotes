module Entry.Id exposing (Id, decoder, toString)

import Json.Decode as D exposing (Decoder)


type Id
    = Id String


toString : Id -> String
toString (Id id) =
    id


{-| TODO: is there some kind of validation we could do here?
-}
fromString : String -> Id
fromString str =
    Id str


decoder : Decoder Id
decoder =
    D.string
        |> D.map fromString
