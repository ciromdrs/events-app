module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Feed
import Html exposing (text)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, s, string)


type alias Model =
    { page : Page
    , key : Nav.Key
    , url : Url
    }


type Page
    = FeedPage Feed.Model
    | NotFound


type Route
    = FeedRoute


type Msg
    = ClickedLink Browser.UrlRequest
    | ChangedUrl Url
    | GotFeedMsg Feed.Msg



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }



--INIT


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init () url key =
    updateUrl url { page = NotFound, key = key, url = url }


updateUrl : Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Parser.parse parser url of
        Just FeedRoute ->
            toFeed model <| Feed.init ()

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


parser : Parser (Route -> a) a
parser =
    Parser.oneOf
        [ Parser.map FeedRoute Parser.top
        ]


toFeed : Model -> ( Feed.Model, Cmd Feed.Msg ) -> ( Model, Cmd Msg )
toFeed model ( feedModel, cmd ) =
    ( { model | page = FeedPage feedModel }
    , Cmd.map GotFeedMsg cmd
    )



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case model.page of
                FeedPage feedModel ->
                    Feed.view feedModel
                        |> Html.map GotFeedMsg

                NotFound ->
                    text <| "Resource " ++ Url.toString model.url ++ " not found"
    in
    { title = "Events App"
    , body =
        [ content ]
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( GotFeedMsg feedMsg, FeedPage feedModel ) ->
            toFeed model (Feed.update feedMsg feedModel)

        _ ->
            ( model, Cmd.none )
