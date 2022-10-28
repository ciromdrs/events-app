module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Http



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Sub.none
        }



-- MODEL


type alias Model =
    { text : String }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { text = "Hello, Elm!" }, Cmd.none )



-- UPDATE


type Msg
    = ClickedLoadText
    | GotText (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLoadText ->
            ( model
            , Http.get
                { url = "hello.php"
                , expect = Http.expectString GotText
                }
            )

        GotText result ->
            case result of
                Ok text ->
                    ( { model | text = text }, Cmd.none )

                Err err ->
                    ( { model | text = "Error loading text" }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ text model.text
        , button [ onClick ClickedLoadText ] [ text "Load message" ]
        ]
