module Main exposing (..)

import Browser
import Html exposing (Html, a, button, div, form, i, img, input, label, li, main_, nav, span, text, textarea, ul)
import Html.Attributes exposing (action, attribute, class, for, id, method, name, placeholder, rows, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, bool, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Url.Builder exposing (Root(..), custom)



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
    let
        model =
            { debugText = ""
            , status = Loading
            , posts = []
            , postFormData = { user = "default", text = "" }
            }
    in
    ( model
    , getRecentPostsCmd model
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
    , likedByCurrentUser : Bool
    }



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List Post))
    | ClickedPost
    | Posted (Result Http.Error String)
    | ChangedPostText String
    | ChangedPostUser String
    | ClickedLike Post
    | ClickedDislike Post
    | LikedDisliked (Result Http.Error String)


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
                        [ Http.stringPart "user" model.postFormData.user
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
            ( newModel, getRecentPostsCmd newModel )

        ClickedLike post ->
            ( model
            , Http.post
                { url = "api/likes"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "user" model.postFormData.user
                        , Http.stringPart "post" (String.fromInt post.id)
                        ]
                , expect = Http.expectString LikedDisliked
                }
            )

        ClickedDislike post ->
            ( model
            , Http.request
                { method = "DELETE"
                , headers = []
                , url =
                    custom Relative
                        [ "api", "likes" ]
                        [ Url.Builder.string "user" model.postFormData.user
                        , Url.Builder.string "post" (String.fromInt post.id)
                        ]
                        Nothing
                , body = Http.emptyBody
                , expect = Http.expectString LikedDisliked
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        LikedDisliked result ->
            case result of
                Ok _ ->
                    ( model, getRecentPostsCmd model )

                Err errMessage ->
                    ( { model | debugText = Debug.toString errMessage }, Cmd.none )


getRecentPostsCmd : Model -> Cmd Msg
getRecentPostsCmd model =
    Http.get
        { url =
            custom Relative
                [ "api", "posts" ]
                [ Url.Builder.string "current_user" model.postFormData.user ]
                Nothing
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
        , img
            [ class "like-button"
            , src
                (if post.likedByCurrentUser then
                    "/static/filled-heart.png"

                 else
                    "/static/empty-heart.png"
                )
            , if post.likedByCurrentUser then
                onClick (ClickedDislike post)

              else
                onClick (ClickedLike post)
            ]
            []
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
                , id "user"
                , name "user"
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
        |> required "liked_by_current_user" bool
