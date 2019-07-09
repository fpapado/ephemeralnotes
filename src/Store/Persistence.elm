module Store.Persistence exposing
    ( Persistence(..)
    , decoder
    , toString
    , view
    )

import Html exposing (Html, div, text)
import Json.Decode as JD
import Json.Encode as JE



{-
   Component that, when connected, check for storage peristence.
   Module that deals with persistence state, checking from the navigator and so on.

   Persisted storage is tricky! It might require a permission, which might be automatically granted
   by the user agent. For example, Chrome might provide it if the app is installed, while Firefox might always prompt.
   It is also possible that persistence is not supported, or that persistence is supported but
   the Permissions API is not! In some cases, thus, we should pick a time to prompt the user,
   ideally with an explanation as to why. In other cases, we might not ever be able to persist,
   or even automatically be able to. Fun times :D

   Check the State type below for the various possible states of persistence.


   The Storage Standard is short and sweet, and outlines these concerns:
   @see https://storage.spec.whatwg.org/
-}


type Persistence
    = -- The storage is already persistent.
      Persisted
      -- The storage *could* be persisted if we prompted the user, upon interaction.
    | ShouldPrompt
      -- Persisting storage is not supported, for example if `navigator.storage` is undefined.
    | Unsupported
      -- The user or UA has denied the prompt (either as a result of a prompt now, or in the past).
    | Denied
      -- (Rare): We tried to persist but failed; internal error, perhaps disk I/O.
    | PersistenceFailed



-- JSON


toString : Persistence -> String
toString persistence =
    case persistence of
        Persisted ->
            "Persisted"

        ShouldPrompt ->
            "ShouldPrompt"

        Unsupported ->
            "Unsupported"

        Denied ->
            "Denied"

        PersistenceFailed ->
            "PersistenceFailed"


decoder : JD.Decoder Persistence
decoder =
    JD.string
        |> JD.andThen
            (\tag ->
                case tag of
                    "Persisted" ->
                        JD.succeed Persisted

                    "ShouldPrompt" ->
                        JD.succeed ShouldPrompt

                    "Unsupported" ->
                        JD.succeed Unsupported

                    "Denied" ->
                        JD.succeed Denied

                    "PersistenceFailed" ->
                        JD.succeed PersistenceFailed

                    _ ->
                        JD.fail ("Did not expect tag " ++ tag)
            )



-- VIEW
-- A curated view based on the persistence state. Tries to inform the user of the possiblities.
-- It is in this module because it is closely related to what we want to communicate,
-- but you could decide otherwise!


view : Persistence -> Html msg
view persistence =
    let
        explanation =
            case persistence of
                Unsupported ->
                    "This browser might clear entries, if storage space is running low. It unlikely, but could happen. Take care to export your data if your storage space is running low."

                Denied ->
                    "The permission to store entries permanently has been denied. The browser might clear them up, if storage space is running low. It is unlikely, but could happen. Take care to export your data if your storage space is running low."

                PersistenceFailed ->
                    "We could not ensure that entries get stored permanently due to an internal error. Will try again."

                ShouldPrompt ->
                    "This browser might clear entries, if storage space is running low. Please press the button below to give permission to store the entries permanently."

                Persisted ->
                    "Entries will get stored permanently."
    in
    div [] [ text explanation ]
