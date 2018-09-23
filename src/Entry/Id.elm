module Entry.Id exposing (Id, decoder, generate, toString)

import Json.Decode as D exposing (Decoder)


type Id
    = Id String


{-| TODO: make random/uuid
-}
generate : Id
generate =
    Id "TODO_MAKE_RANDOM"


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
