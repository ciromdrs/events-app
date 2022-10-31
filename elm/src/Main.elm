module Main exposing (..)

import Browser
import Html exposing (Html, button, div, main_, span, text)
import Html.Attributes exposing (class)
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
    ( { debugText = ""
      , status = Loading
      , posts = []
      }
    , Http.get
        { url = "api/posts"
        , expect = Http.expectJson GotPosts (list postDecoder)
        }
    )



-- MODEL


type alias Model =
    { debugText : String
    , status : Status
    , posts : List Post
    }


type Status
    = Loading
    | Idle


type alias Post =
    { id : Int
    , user : String
    , text : String
    , created : String
    }



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List Post))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotPosts result ->
            let
                modelIdle =
                    { model | status = Idle }
            in
            case result of
                Ok posts ->
                    ( { modelIdle | posts = posts }, Cmd.none )

                Err err ->
                    case err of
                        Http.BadBody errMessage ->
                            ( { modelIdle | debugText = errMessage }, Cmd.none )

                        _ ->
                            ( { modelIdle | debugText = "Unknown error" }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    main_ [ class "mdl-layout__content mdl-color--grey-100" ]
        [ div
            [ class "mdl-grid" ]
            [ div []
                ((case model.status of
                    Loading ->
                        [ text "Loading recent posts..." ]

                    _ ->
                        []
                 )
                    ++ List.map
                        (\post ->
                            div [ class "mdl-color--white mdl-shadow--2dp mdl-cell mdl-cell--6-col" ]
                                [ span [ class "post-user" ] [ text post.user ]
                                , span [ class "post-date" ] [ text (" on " ++ post.created) ]
                                , div [] [ text post.text ]
                                ]
                        )
                        model.posts
                )
            ]
        ]


postDecoder : Decoder Post
postDecoder =
    succeed Post
        |> required "id" int
        |> required "user" string
        |> required "text" string
        |> required "created" string
