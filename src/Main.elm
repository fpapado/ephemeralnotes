module Main exposing (main)

-- import Page.Data as Data
-- import Page.Map as Map

import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Entry.Entry as Entry exposing (Entry)
import Entry.Id
import Html exposing (..)
import Html.Attributes as HA exposing (class)
import Html.Events as HE exposing (onClick)
import Json.Decode as JD exposing (Value)
import Log
import Page exposing (FocusState(..), Page)
import Page.Blank as Blank
import Page.Data as Data
import Page.Home as Home
import Page.Map as Map
import Page.NotFound as NotFound
import Process
import RemoteData exposing (RemoteData)
import Route exposing (Route)
import ServiceWorker as SW
import Set exposing (Set)
import Store
import Task
import Time
import Ui exposing (..)
import Url exposing (Url)


type alias Model =
    { navKey : Nav.Key
    , page : PageModel
    , focusState : Page.FocusState
    , swUpdate : SW.SwUpdate
    , installPrompt : SW.InstallPrompt
    , entries : RemoteData String (List Entry)
    }


type PageModel
    = Redirect
    | NotFound
    | Home Home.Model
    | Map
    | Data Data.Model



-- MODEL


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        -- Get the updated page model and init cmd
        ( modelWithPage, cmdWithPage ) =
            changeRouteTo (Route.fromUrl url)
                { navKey = navKey
                , page = Redirect
                , focusState = NotYetFocused
                , swUpdate = SW.updateNone
                , installPrompt = SW.installPromptNone
                , entries = RemoteData.Loading
                }
    in
    -- Return those, plus the Main init msg
    ( modelWithPage, Cmd.batch [ Store.getEntries, cmdWithPage ] )



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
                    Page.view { activePage = page, focusState = model.focusState, onBlurredMain = FocusedPastMain, toOutMsg = toMsg } config
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
            viewPage Page.Map (\_ -> Ignored) (Map.view { entries = model.entries })

        Data dataModel ->
            -- Data does not have a model, but it does have a Msg
            viewPage Page.Data GotDataMsg (Data.view { entries = model.entries } dataModel)



-- UPDATE


type Msg
    = Ignored
      -- URL handling
    | ChangedRoute (Maybe Route)
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
      -- Focus handling
    | GotFocusResult (Result Dom.Error ())
    | FocusedPastMain
      -- Pages
    | GotHomeMsg Home.Msg
    | GotDataMsg Data.Msg
      -- Subs
    | FromServiceWorker SW.ToElm
    | FromStore Store.ToElm
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



-- Data.init
--     |> updateWith (\m -> { model | page = Data m }) GotDataMsg model


{-| Deferred focus after a setTimeout, to allow the rendering to settle
TODO: Test this with Process.sleep 0 - 200ms
-}
focus : String -> Cmd Msg
focus id =
    Dom.focus id
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
                    , Cmd.batch [ Nav.pushUrl model.navKey (Url.toString url), focus "main" ]
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

                -- TODO: Add to the model here
                Store.GotBatchImportedEntries res ->
                    let
                        existingEntries =
                            model.entries

                        newEntries =
                            case res of
                                Ok importedEntries ->
                                    -- Merge the two data sources
                                    RemoteData.map
                                        (mergeEntryLists importedEntries)
                                        existingEntries

                                Err err ->
                                    existingEntries
                    in
                    ( { model | entries = newEntries }, Cmd.none )

                Store.GotEntry entryRes ->
                    let
                        entryData =
                            RemoteData.fromResult entryRes

                        -- Merge the two data sources
                        newEntries =
                            RemoteData.map2 (\entry entries -> entry :: entries) entryData model.entries
                    in
                    ( { model | entries = newEntries }, Cmd.none )

                Store.BadMessage err ->
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

        alwaysSubs =
            [ Sub.map FromServiceWorker SW.sub, Sub.map FromStore Store.sub ]
    in
    Sub.batch (alwaysSubs ++ [ pageSubs ])



-- VIEW
-- Service Worker Update + Install


viewUpdatePrompt : SW.SwUpdate -> Html Msg
viewUpdatePrompt swUpdate =
    notificationRegion []
        [ SW.viewSwUpdate swUpdate
            { none = div [] []
            , available =
                calloutContainer [ class "z-9999" ]
                    [ prompt [ class "na2" ]
                        [ div [ class "measure ma2" ]
                            [ h2 [ class "mv0 f5 fw4 lh-title" ] [ text "A new version is available. You can reload now to get it." ]
                            ]
                        , div [ class "ma2 flex" ]
                            [ styledButtonBlue False [ onClick AcceptUpdate, class "mr2" ] [ text "Reload" ]
                            , styledButtonBlue False [ onClick DeferUpdate ] [ text "Later" ]
                            ]
                        ]
                    ]
            , accepted = div [] []
            , deferred = div [] []
            }
        ]


viewInstallPrompt : SW.InstallPrompt -> Html Msg
viewInstallPrompt installPrompt =
    notificationRegion []
        [ SW.viewInstallPrompt installPrompt
            { none = div [] []
            , available =
                calloutContainer [ class "z-9999" ]
                    [ prompt [ class "na2" ]
                        [ div [ class "measure ma2" ]
                            [ h2 [ class "mv0 f5 fw4 lh-title" ] [ text "Add Ephemeral to your home screen?" ]
                            ]
                        , div [ class "ma2 flex" ]
                            [ styledButtonBlue False [ onClick AcceptInstallPrompt, class "mr2" ] [ text "Add" ]
                            , styledButtonBlue False [ onClick DeferInstallPrompt ] [ text "Dismiss" ]
                            ]
                        ]
                    ]
            }
        ]


{-| Merge two lists of entries, keeping only a single id, prioritising the first list. |
-}
mergeEntryLists : List Entry -> List Entry -> List Entry
mergeEntryLists list1 list2 =
    let
        rawMerged =
            list1 ++ list2

        initState =
            ( [], Set.empty )

        addIfNotSeen : Entry -> ( List Entry, Set String ) -> ( List Entry, Set String )
        addIfNotSeen candidate ( listSoFar, seenIds ) =
            let
                -- Extract the id from the Entry, so we can compare it
                -- TODO: Consider a tie-breaker with Version as well
                id =
                    case candidate of
                        Entry.V1 entry ->
                            Entry.Id.toString entry.id

                haveSeenIdBefore =
                    Set.member id seenIds
            in
            case haveSeenIdBefore of
                -- If the id is in the ones we have seen, skip it
                True ->
                    ( listSoFar, seenIds )

                -- If the id is not in the ones we have seen, add the item to the list
                -- and the ids to the set
                False ->
                    ( candidate :: listSoFar, Set.insert id seenIds )
    in
    List.foldl addIfNotSeen initState rawMerged
        |> Tuple.first



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
