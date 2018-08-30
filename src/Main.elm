module Main exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Log
import Page exposing (Page)
import Page.Blank as Blank
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Task
import Time
import Url exposing (Url)


type alias Model =
    { navKey : Nav.Key
    , page : PageModel
    }


type PageModel
    = Redirect
    | NotFound
    | Home Home.Model



-- MODEL


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    changeRouteTo (Route.fromUrl url)
        { navKey = navKey, page = Redirect }



-- VIEW


view : Model -> Document Msg
view model =
    let
        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view page config
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model.page of
        Redirect ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        NotFound ->
            viewPage Page.Other (\_ -> Ignored) NotFound.view

        Home home ->
            viewPage Page.Home GotHomeMsg (Home.view home)



-- UPDATE


type Msg
    = Ignored
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotFocusResult (Result Dom.Error ())
    | GotHomeMsg Home.Msg


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just Route.Home ->
            Home.init
                |> updateWith (\m -> { model | page = Home m }) GotHomeMsg model


focus : String -> Cmd Msg
focus id =
    Task.attempt GotFocusResult (Dom.focus id)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Cmd.batch [ Nav.pushUrl model.navKey (Url.toString url), focus "main" ]
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( GotFocusResult res, _ ) ->
            case res of
                Ok () ->
                    ( model, Cmd.none )

                Err (Dom.NotFound id) ->
                    ( model, Log.error ("Dom.Error.NotFound" ++ id) )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        ( GotHomeMsg subMsg, { page } ) ->
            case page of
                Home home ->
                    Home.update subMsg home
                        |> updateWith (\m -> { model | page = Home m }) GotHomeMsg model

                _ ->
                    ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        NotFound ->
            Sub.none

        Redirect ->
            Sub.none

        Home home ->
            Sub.map GotHomeMsg (Home.subscriptions home)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
