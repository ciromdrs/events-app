module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { text = "Hello from Elm!" }
    , Cmd.none
    )



-- MODEL


type alias Model =
    { text : String }


type alias Post =
    { id : Int
    , user : String
    , text : String
    , created : String
    }



-- UPDATE


type Msg
    = ClickedLoadText
    | GotPosts (Result Http.Error (List Post))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLoadText ->
            ( model
            , Http.get
                { url = "api/posts"
                , expect = Http.expectJson GotPosts (list postDecoder)
                }
            )

        GotPosts result ->
            case result of
                Ok posts ->
                    ( { model | text = Debug.toString posts }, Cmd.none )

                Err err ->
                    case err of
                        Http.BadBody errMessage ->
                            ( { model | text = errMessage }, Cmd.none )

                        _ ->
                            ( { model | text = "Unknown error" }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text model.text
        , button [ onClick ClickedLoadText ] [ text "Load message" ]
        ]


postDecoder : Decoder Post
postDecoder =
    succeed Post
        |> required "id" int
        |> required "user" string
        |> required "text" string
        |> required "created" string
