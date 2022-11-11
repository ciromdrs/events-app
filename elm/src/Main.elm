module Main exposing (..)

import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, div, img, input, main_, span, text, textarea)
import Html.Attributes exposing (class, id, name, placeholder, rows, src, type_, value)
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
            , postFormData = { user = "default", text = "", photo = Nothing }
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
    , postFormData : { user : String, text : String, photo : Maybe File }
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
    , imgUrl : String
    }



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List Post))
    | ClickedPost
    | Posted (Result Http.Error String)
    | ChangedPostText String
    | ChangedPostUser String
    | ChangedPostPhoto File
    | PickPhoto
    | ClickedLike Post
    | ClickedDislike Post
    | LikedDisliked (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        formData =
            model.postFormData
    in
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
                newData =
                    { formData | user = new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        ChangedPostText new ->
            let
                newData =
                    { formData | text = new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        ChangedPostPhoto new ->
            let
                newData =
                    { formData | photo = Just new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        PickPhoto ->
            ( model
            , Select.file [ "image/*" ] ChangedPostPhoto
            )

        ClickedPost ->
            ( model
            , case model.postFormData.photo of
                Just photo ->
                    Http.post
                        { url = "api/posts"
                        , body =
                            Http.multipartBody
                                [ Http.stringPart "user" model.postFormData.user
                                , Http.stringPart "text" model.postFormData.text
                                , Http.filePart "photo" photo
                                ]
                        , expect = Http.expectString Posted
                        }

                Nothing ->
                    -- Show 'required' message
                    Cmd.none
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

                                clearFields =
                                    { oldFormData | text = "", photo = Nothing }
                            in
                            { modelLoading | postFormData = clearFields }

                        Err error ->
                            { modelLoading | debugText = Debug.toString result }
            in
            ( newModel, getRecentPostsCmd newModel )

        ClickedLike post ->
            ( model
            , Http.post
                { url = "api/posts/" ++ String.fromInt post.id ++ "/likes"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "user" model.postFormData.user
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
                        [ "api", "posts", String.fromInt post.id, "likes" ]
                        [ Url.Builder.string "user" model.postFormData.user
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
        [ img [ class "post-image", src post.imgUrl ] []
        , span [ class "post-user" ] [ text post.user ]
        , span [ class "post-date" ] [ text (" on " ++ post.created) ]
        , div [ class "post-text" ] [ text post.text ]
        , img
            [ class
                (if post.likedByCurrentUser then
                    "dislike-button"

                 else
                    "like-button"
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

        photo =
            case model.postFormData.photo of
                Just photoFile ->
                    File.name photoFile

                Nothing ->
                    ""
    in
    div [ class "post" ]
        [ div
            []
            [ button [ class "small", onClick PickPhoto ] [ text "Select Photo" ]
            , span [] [ text photo ]
            , emptyDiv
            , input
                [ type_ "text"
                , id "user"
                , name "user"
                , class "post-form-input post-user"
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
                , class "post-text-input post-form-input"
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
        |> required "imgUrl" string
