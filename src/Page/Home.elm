module Page.Home exposing (Model, Msg(..), init, subscriptions, update, view, viewBanner)

{-| The homepage. You can get here via either the / route.
-}

import Html exposing (..)
import Html.Attributes exposing (class, href)
import ServiceWorker as SW
import Task exposing (Task)
import Time
import Ui exposing (heading)



-- MODEL


type alias Model =
    { timeZone : Time.Zone
    , update : SW.Update
    }


init : ( Model, Cmd Msg )
init =
    ( { timeZone = Time.utc
      , update = SW.None
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        ]
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Ephemeral"
    , content =
        div
            [ class "home-page" ]
            [ viewBanner
            , a [ class "link underline", href "/404" ] [ text "404 page" ]
            ]
    }


viewBanner : Html msg
viewBanner =
    div [ class "banner" ]
        [ div [ class "container" ]
            [ heading [] [ text "Ephemeral" ]
            , p [] [ text "Write down words as you encounter them." ]
            ]
        ]



-- UPDATE


type Msg
    = GotTimeZone Time.Zone
    | ServiceWorker SW.ToElm


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTimeZone tz ->
            ( { model | timeZone = tz }, Cmd.none )

        ServiceWorker swMsg ->
            case swMsg of
                SW.UpdateAvailable ->
                    ( { model | update = SW.Available }
                    , Cmd.none
                    )

                SW.DecodingError err ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map ServiceWorker SW.sub
