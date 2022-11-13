module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Feed
import Html exposing (text)
import Url exposing (Url)
import Url.Builder
import Url.Parser as Parser exposing ((</>), Parser, s, string)
import Users


type alias Model =
    { page : Page
    , key : Nav.Key
    , url : Url
    , authToken : Maybe String
    }


type Page
    = NotFound
    | FeedPage Feed.Model
    | UsersPage Users.Model


type Route
    = FeedRoute
    | UsersRoute


type Msg
    = RequestedUrl Browser.UrlRequest
    | ChangedUrl Url
    | GotFeedMsg Feed.Msg
    | GotUsersMsg Users.Msg



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = RequestedUrl
        , onUrlChange = ChangedUrl
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }



--INIT


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    updateUrl url
        { page = NotFound
        , key = key
        , url = url
        , authToken = Nothing
        }



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case model.page of
                NotFound ->
                    text <| "Resource " ++ Url.toString model.url ++ " not found"

                FeedPage feedModel ->
                    Feed.view feedModel
                        |> Html.map GotFeedMsg

                UsersPage usersModel ->
                    Users.view usersModel
                        |> Html.map GotUsersMsg
    in
    { title = "Events App"
    , body =
        [ content ]
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        redirectTo : Model -> String -> ( Model, Cmd Msg )
        redirectTo newModel url =
            ( newModel, Nav.pushUrl newModel.key url )

        logIgnoredMessage ignoredMsg =
            Debug.log ("Ignored message: " ++ Debug.toString ignoredMsg) ( model, Cmd.none )
    in
    case ( msg, model.page ) of
        ( ChangedUrl url, _ ) ->
            updateUrl url model

        ( RequestedUrl urlRequest, _ ) ->
            case urlRequest of
                Browser.External href ->
                    ( model, Nav.load href )

                Browser.Internal url ->
                    redirectTo model (Url.toString url)

        ( GotFeedMsg feedMsg, FeedPage feedModel ) ->
            toFeed model (Feed.update feedMsg feedModel)

        ( GotFeedMsg _, _ ) ->
            logIgnoredMessage GotFeedMsg

        ( GotUsersMsg (Users.Authenticated token redirectUrl), UsersPage usersModel ) ->
            -- User has authenticated. Save token and redirect.
            let
                modelWithToken =
                    { model | authToken = Just token }
            in
            case Parser.parse parser redirectUrl of
                Just UsersRoute ->
                    redirectTo modelWithToken "feed"

                _ ->
                    updateUrl redirectUrl modelWithToken

        ( GotUsersMsg usersMsg, UsersPage usersModel ) ->
            toUsers model (Users.update usersMsg usersModel)

        ( GotUsersMsg _, _ ) ->
            logIgnoredMessage GotUsersMsg


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Parser.parse parser url of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just FeedRoute ->
            toFeed model <| Feed.init ()

        Just UsersRoute ->
            toUsers model <| Users.init () model.url


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map FeedRoute Parser.top
        , Parser.map FeedRoute (s "feed")
        , Parser.map UsersRoute (s "login")
        ]


toFeed : Model -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
toFeed model ( feedModel, cmd ) =
    ( { model | page = FeedPage feedModel }
    , Cmd.map GotFeedMsg cmd
    )


toUsers : Model -> ( Users.Model, Cmd Users.Msg ) -> ( Model, Cmd Msg )
toUsers model ( usersModel, cmd ) =
    ( { model | page = UsersPage usersModel }
    , Cmd.map GotUsersMsg cmd
    )
