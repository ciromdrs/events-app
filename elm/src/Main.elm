module Main exposing (..)

import Browser
import Html exposing (Html, a, button, div, form, i, input, label, li, main_, nav, span, text, textarea, ul)
import Html.Attributes exposing (action, attribute, class, for, id, method, name, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput)
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
      , postFormData = { user = "default", text = "" }
      }
    , getRecentPostsCmd
    )



-- MODEL


type alias Model =
    { debugText : String
    , status : Status
    , posts : List Post
    , postFormData : { user : String, text : String }
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
    | ClickedPost
    | Posted (Result Http.Error String)
    | ChangedPostText String
    | ChangedPostUser String


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

        ChangedPostUser new ->
            let
                formData =
                    model.postFormData

                newData =
                    { formData | user = new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        ChangedPostText new ->
            let
                formData =
                    model.postFormData

                newData =
                    { formData | text = new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        ClickedPost ->
            ( model
            , Http.post
                { url = "api/posts"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "username" model.postFormData.user
                        , Http.stringPart "text" model.postFormData.text
                        ]
                , expect = Http.expectString Posted
                }
            )

        Posted result ->
            let
                modelLoading =
                    { model | status = Loading }

                newModel =
                    case result of
                        Ok value ->
                            let
                                oldFormData =
                                    modelLoading.postFormData

                                clearText =
                                    { oldFormData | text = "" }
                            in
                            { modelLoading | postFormData = clearText }

                        Err error ->
                            { modelLoading | debugText = Debug.toString result }
            in
            ( newModel, getRecentPostsCmd )


getRecentPostsCmd : Cmd Msg
getRecentPostsCmd =
    Http.get
        { url = "api/posts"
        , expect = Http.expectJson GotPosts (list postDecoder)
        }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ div [] [ span [] [ text model.debugText ] ]
        , main_ [ class "main-content" ]
            [ viewPostForm model
            , div
                []
                ((case model.status of
                    Loading ->
                        [ div [] [ text "Loading recent posts..." ] ]

                    _ ->
                        []
                 )
                    ++ List.map viewPost model.posts
                )
            ]
        ]


viewPost : Post -> Html Msg
viewPost post =
    div [ class "post" ]
        [ span [ class "post-user" ] [ text post.user ]
        , span [ class "post-date" ] [ text (" on " ++ post.created) ]
        , div [ class "post-text" ] [ text post.text ]
        ]


viewPostForm : Model -> Html Msg
viewPostForm model =
    let
        emptyDiv =
            div [] []
    in
    div [ class "post" ]
        [ div
            []
            [ input
                [ type_ "text"
                , id "username"
                , name "username"
                , onInput ChangedPostUser
                , placeholder "User"
                , value model.postFormData.user
                , Html.Attributes.required True
                ]
                []
            ]
        , emptyDiv
        , div []
            [ textarea
                [ id "text"
                , class "post-text-input"
                , rows 3
                , onInput ChangedPostText
                , placeholder "Write something..."
                , value model.postFormData.text
                ]
                []
            ]
        , emptyDiv
        , button
            [ onClick ClickedPost ]
            [ text "Post" ]
        ]


postDecoder : Decoder Post
postDecoder =
    succeed Post
        |> required "id" int
        |> required "user" string
        |> required "text" string
        |> required "created" string
