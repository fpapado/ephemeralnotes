module HumanError exposing
    ( Expectation(..)
    , HumanError
    , Recovery(..)
    , RecoveryLevel(..)
    , toString
    )

{-| An attempt to encode error displays that are meant to communicate:

  - What the problem was

  - Whether it is expected or not

  - Whether the user can do anything about it, and if so, what

    NOTE: This might be either a good idea, or a truly tech-obsessed one.
    To be clear, I don' think tech will save us here.
    Still, I think there's something valuable to being able to account for most errors
    in our application, or at least having the compiler push us to think about
    how we present the errors. Take the `toString` function with a grain of salt,
    and go ahead and create your own interpretations from these!

-}


type alias HumanError =
    { expectation : Expectation
    , summary : Maybe String
    , recovery : RecoveryLevel
    }


type Expectation
    = Expected
    | Unexpected


type RecoveryLevel
    = Recoverable Recovery
    | Unrecoverable


type Recovery
    = TryAgain
    | CustomRecovery String


toString : HumanError -> String
toString err =
    String.join " "
        [ "We encountered an"
        , case err.expectation of
            Expected ->
                "error."

            Unexpected ->
                "unexpected error, that shouldn't be possible."
        , case err.summary of
            Nothing ->
                ""

            Just details ->
                details
        , case err.recovery of
            Unrecoverable ->
                "There is no way to recover from it."

            Recoverable recoveryAction ->
                case recoveryAction of
                    TryAgain ->
                        "You can try performing the action again."

                    CustomRecovery customRec ->
                        customRec
        ]
