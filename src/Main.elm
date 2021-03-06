module Main exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import DarkMode
import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Html exposing (..)
import Html.Attributes as HA exposing (class)
import Html.Events as HE exposing (onClick)
import Json.Decode as JD exposing (Value)
import Log
import Page exposing (FocusState(..), Page)
import Page.About as About
import Page.Blank as Blank
import Page.Data as Data
import Page.Home as Home
import Page.Map as Map
import Page.NotFound as NotFound
import Page.Settings as Settings
import Process
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import ServiceWorker as SW
import Set exposing (Set)
import Store
import Store.Persistence as Persistence exposing (Persistence)
import Task exposing (Task)
import Time
import Ui exposing (..)
import Url exposing (Url)



-- MODEL


type alias Model =
    { navKey : Nav.Key
    , page : PageModel
    , focusState : Page.FocusState
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    , entries : RemoteData Store.RequestError (List Entry)
    , darkMode : DarkMode.Mode
    , persistence : Maybe Persistence
    }


type PageModel
    = Redirect
    | NotFound
    | Home Home.Model
    | Map
    | Data Data.Model
    | Settings
    | About



-- INIT


type alias Flags =
    { initDarkMode : DarkMode.Mode
    }


defaultFlags : Flags
defaultFlags =
    { initDarkMode = DarkMode.Light
    }


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "initialDarkMode" JD.string
            |> JD.andThen DarkMode.modeDecoder
        )


init : JD.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url navKey =
    let
        -- Decode the flags, and use their data
        flagRes =
            JD.decodeValue flagsDecoder flagsValue

        -- Unwrap and skip the flag decoding error, passing default flags if so
        -- This is probably fine, since atm flags are meant to be optional/preferences
        flags =
            case flagRes of
                Ok flags_ ->
                    flags_

                Err decodingError ->
                    defaultFlags

        -- Get the updated page model and init cmd
        ( modelWithPage, cmdWithPage ) =
            changeRouteTo (Route.fromUrl url)
                { navKey = navKey
                , page = Redirect
                , focusState = NotYetFocused
                , swUpdate = SW.updateNone
                , installPrompt = SW.installPromptNone
                , entries = RemoteData.Loading
                , darkMode = flags.initDarkMode
                , persistence = Maybe.Nothing
                }
    in
    -- Return the page model and commands, as well as common "initial" commands
    ( modelWithPage
    , Cmd.batch [ Store.getEntries, Store.checkPersistenceWithoutPrompt, cmdWithPage ]
    )



-- VIEW


view : Model -> Document Msg
view model =
    let
        globalPopups =
            [ -- TODO: Move to main or page, or somewhere?
              viewUpdatePrompt model.swUpdate
            , viewInstallPrompt model.installPrompt
            ]

        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view
                        { activePage = page
                        , focusState = model.focusState
                        , onBlurredMain = FocusedPastMain
                        , onPressedBack = UserPressedBack
                        , toOutMsg = toMsg
                        }
                        config
            in
            { title = title
            , body = body ++ globalPopups
            }
    in
    case model.page of
        Redirect ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        NotFound ->
            viewPage Page.Other (\_ -> Ignored) NotFound.view

        Home homeModel ->
            viewPage Page.Home GotHomeMsg (Home.view { entries = model.entries } homeModel)

        Map ->
            -- Map does not have any Msg at the moment, so we ignore it
            viewPage Page.Map (\_ -> Ignored) (Map.view { entries = model.entries, darkMode = model.darkMode })

        Data dataModel ->
            -- Data does not have a model, but it does have a Msg
            viewPage Page.Data GotDataMsg (Data.view { entries = model.entries, persistence = model.persistence } dataModel)

        Settings ->
            -- Data does not have a model, but it does have a Msg
            viewPage Page.Settings GotSettingsMsg (Settings.view { darkMode = model.darkMode })

        About ->
            -- About does not have a model, or a message
            viewPage Page.About (\_ -> Ignored) About.view



-- UPDATE


type Msg
    = Ignored
      -- URL handling
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
      -- Back URL Handling
    | UserPressedBack
      -- Focus handling
    | GotFocusResult (Result Dom.Error ())
    | FocusedPastMain
      -- Pages
    | GotHomeMsg Home.Msg
    | GotDataMsg Data.Msg
    | GotSettingsMsg Settings.Msg
      -- Subs
    | FromServiceWorker SW.ToElm
    | FromStore Store.ToElm
    | FromDarkMode DarkMode.ToElm
      -- SW prompts
    | AcceptUpdate
    | DeferUpdate
    | AcceptInstallPrompt
    | DeferInstallPrompt



-- | GotMapMsg Map.Msg
-- | GotDataMsg Data.Msg


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just Route.Home ->
            Home.init
                |> updateWith (\m -> { model | page = Home m }) GotHomeMsg model

        Just Route.Map ->
            -- Map page has no initialiser
            ( { model | page = Map }, Cmd.none )

        Just Route.Data ->
            Data.init
                |> updateWith (\m -> { model | page = Data m }) GotDataMsg model

        Just Route.Settings ->
            -- Settings has no initialiser
            ( { model | page = Settings }, Cmd.none )

        Just Route.About ->
            -- About has no initialiser
            ( { model | page = About }, Cmd.none )


{-| Set focus to an element, after a setTimeout, to allow the rendering to settle
This is important for triggering some Screen Reader announcements correctly,
and might also help with not invalidating browser layout.
NOTE: This is not necessarily the best strategy, and other ways of communicating
page loads to Assistive Technology users could be considered.
-}
delayedFocus : String -> Task Dom.Error ()
delayedFocus id =
    Process.sleep 100
        |> Task.andThen (\() -> Dom.focus id)


scrollTopAndFocusMain : Cmd Msg
scrollTopAndFocusMain =
    -- NOTE: It is important that we Dom.setViewport *before* the delayed focus
    -- This allows setViewport to piggyback on the frist animation frame (rAF), before
    -- the macro task (setTimeout) of Process.sleep, and the second rAF of Dom.focus
    Dom.setViewport 0 0
        |> Task.andThen (\() -> delayedFocus "main")
        |> Task.attempt GotFocusResult


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            -- On Internal Link Click, attempt to focus "main"
            case urlRequest of
                Browser.Internal url ->
                    ( { model | focusState = Focusing }
                    , Cmd.batch
                        [ Nav.pushUrl model.navKey (Url.toString url)
                        , scrollTopAndFocusMain
                        ]
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( GotFocusResult res, _ ) ->
            case res of
                -- If we focused Ok, then set the state
                Ok () ->
                    ( { model | focusState = FocusOnMain }, Cmd.none )

                -- Otherwise, set the state and log
                Err (Dom.NotFound id) ->
                    ( { model | focusState = FocusErr }, Log.error ("Dom.Error.NotFound" ++ id) )

        ( FocusedPastMain, _ ) ->
            ( { model | focusState = FocusPastMain }, Cmd.none )

        ( UserPressedBack, _ ) ->
            ( model
            , Cmd.batch
                [ Nav.back model.navKey 1
                , scrollTopAndFocusMain
                ]
            )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ChangedRoute route, _ ) ->
            changeRouteTo route model

        -- Store subscription messages
        ( FromStore storeMsg, _ ) ->
            case storeMsg of
                -- For GotEntries, the expectation is that we replace the entry list completely
                Store.GotEntries entries ->
                    ( { model | entries = RemoteData.Success entries }, Cmd.none )

                Store.GotEntry entryRes ->
                    let
                        entryData =
                            RemoteData.fromResult entryRes

                        -- Merge the two data sources
                        newEntries =
                            RemoteData.map2 (\entry entries -> entry :: entries) entryData model.entries
                    in
                    ( { model | entries = newEntries }, Cmd.none )

                Store.GotBatchImportedEntries num ->
                    ( model, Cmd.none )

                Store.GotPersistence persistence ->
                    ( { model | persistence = Maybe.Just persistence }, Cmd.none )

                Store.BadMessage err ->
                    ( model, Log.error (JD.errorToString err) )

        -- Dark mode
        ( FromDarkMode darkModeMsg, _ ) ->
            case darkModeMsg of
                DarkMode.ModeSet mode ->
                    ( { model | darkMode = mode }, Cmd.none )

                DarkMode.BadMessage err ->
                    ( model, Log.error (JD.errorToString err) )

        -- Global page concerns
        -- For example, the Service Worker messages can apear anywhere
        -- Service worker messages
        -- From service worker subscription
        ( FromServiceWorker swMsg, _ ) ->
            case swMsg of
                SW.UpdateAvailable ->
                    ( { model | swUpdate = SW.updateAvailable }
                    , Cmd.none
                    )

                SW.BeforeInstallPrompt ->
                    ( { model | installPrompt = SW.installPromptAvailable }
                    , Cmd.none
                    )

                SW.DecodingError err ->
                    ( model, Log.error (JD.errorToString err) )

        ( AcceptUpdate, _ ) ->
            ( { model | swUpdate = SW.updateAccepted }, SW.acceptUpdate )

        ( DeferUpdate, _ ) ->
            ( { model | swUpdate = SW.updateDeferred }, SW.deferUpdate )

        -- TODO: Fix None to Accepted/Defered
        ( AcceptInstallPrompt, _ ) ->
            ( { model | installPrompt = SW.installPromptNone }, SW.acceptInstallPrompt )

        ( DeferInstallPrompt, _ ) ->
            ( { model | installPrompt = SW.installPromptNone }, SW.deferInstallPrompt )

        ( GotHomeMsg subMsg, { page } ) ->
            case page of
                Home home ->
                    Home.update subMsg home
                        |> updateWith (\m -> { model | page = Home m }) GotHomeMsg model

                _ ->
                    ( model, Cmd.none )

        ( GotDataMsg subMsg, { page } ) ->
            case page of
                Data data ->
                    Data.update subMsg data
                        |> updateWith (\m -> { model | page = Data m }) GotDataMsg model

                _ ->
                    ( model, Cmd.none )

        ( GotSettingsMsg subMsg, { page } ) ->
            case page of
                Settings ->
                    ( (), Settings.update subMsg )
                        |> updateWith (\m -> { model | page = Settings }) GotSettingsMsg model

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
    let
        pageSubs =
            case model.page of
                NotFound ->
                    Sub.none

                Redirect ->
                    Sub.none

                Home home ->
                    Sub.map GotHomeMsg (Home.subscriptions home)

                -- Map does not have any subscriptions
                Map ->
                    Sub.none

                -- Data has subscriptions
                Data data ->
                    Sub.map GotDataMsg (Data.subscriptions data)

                -- Settings does not have any subscriptions
                Settings ->
                    Sub.none

                -- About does not have any subscriptions
                About ->
                    Sub.none

        alwaysSubs =
            [ Sub.map FromServiceWorker SW.sub
            , Sub.map FromStore Store.sub
            , Sub.map FromDarkMode DarkMode.sub
            ]
    in
    Sub.batch (alwaysSubs ++ [ pageSubs ])



-- VIEW
-- Service Worker Update + Install


viewUpdatePrompt : SW.SwUpdate -> Html Msg
viewUpdatePrompt swUpdate =
    let
        headingId =
            "update-prompt-heading"
    in
    div []
        [ SW.viewSwUpdate swUpdate
            { none = text ""
            , available =
                calloutContainer [ class "z-9999" ]
                    [ prompt
                        [ HA.attribute "role" "dialog"
                        , HA.attribute "aria-live" "polite"
                        , HA.attribute "aria-labelledby" headingId
                        ]
                        [ div [ class "measure mb2" ]
                            [ h2
                                [ HA.id headingId
                                , class "mv0 f-paragraph fw6 lh-title tc measure"
                                ]
                                [ text "A new version is available. You can reload now to get it." ]
                            ]
                        , div [ class "flex" ]
                            [ primaryActionButton
                                False
                                [ onClick AcceptUpdate, class "mr2 fw6" ]
                                [ text "Reload" ]
                            , secondaryActionButton
                                False
                                [ onClick DeferUpdate ]
                                [ text "Later" ]
                            ]
                        ]
                    ]
            , accepted = text ""
            , deferred = text ""
            }
        ]


viewInstallPrompt : SW.InstallPrompt -> Html Msg
viewInstallPrompt installPrompt =
    let
        headingId =
            "install-prompt-heading"
    in
    div []
        [ SW.viewInstallPrompt installPrompt
            { none = text ""
            , available =
                calloutContainer [ class "z-9999" ]
                    [ prompt
                        [ HA.attribute "role" "dialog"
                        , HA.attribute "aria-live" "polite"
                        , HA.attribute "aria-labelledby" headingId
                        ]
                        [ div [ class "measure mb2" ]
                            [ h2
                                [ HA.id headingId
                                , class "mv0 f-paragraph fw6 lh-title tc"
                                ]
                                [ text "Add Ephemeral to your home screen?" ]
                            ]
                        , div [ class "flex" ]
                            [ primaryActionButton
                                False
                                [ onClick AcceptInstallPrompt, class "mr2" ]
                                [ text "Add" ]
                            , secondaryActionButton
                                False
                                [ onClick DeferInstallPrompt ]
                                [ text "Dismiss" ]
                            ]
                        ]
                    ]
            }
        ]



-- MAIN


main : Program JD.Value Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
