module Pages.Feed exposing (Model, Msg, page, viewPost)

import Auth
import Browser
import File exposing (File)
import File.Select as Select
import Gen.Params.Feed exposing (Params)
import Gen.Route as Route
import Html exposing (Html, button, div, form, img, input, main_, span, text, textarea)
import Html.Attributes exposing (class, id, name, placeholder, rows, src, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, bool, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Page
import Request exposing (Request)
import Shared
import UI
import Url.Builder exposing (Root(..), custom)
import View exposing (View)



-- MAIN


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.protected.element <|
        \user ->
            { init = init user
            , update = update user
            , view = view user
            , subscriptions = \_ -> Sub.none
            }


init : Auth.User -> ( Model, Cmd Msg )
init user =
    let
        model =
            { debugText = ""
            , status = Loading
            , posts = []
            , postFormData = { text = "", photo = Nothing }
            }
    in
    ( model
    , getRecentPostsCmd user
    )



-- MODEL


type alias Model =
    { debugText : String
    , status : Status
    , posts : List Post
    , postFormData : { text : String, photo : Maybe File }
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
    , likeCount : Int
    , imgUrl : String
    }



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List Post))
    | ClickedPost
    | Posted (Result Http.Error String)
    | ChangedPostText String
    | ChangedPostPhoto File
    | PickPhoto
    | ClickedLike Post
    | ClickedDislike Post
    | LikedDisliked (Result Http.Error String)


update : Auth.User -> Msg -> Model -> ( Model, Cmd Msg )
update user msg model =
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
                                [ Http.stringPart "user" user.name
                                , Http.stringPart "text" model.postFormData.text
                                , Http.filePart "photo" photo
                                ]
                        , expect = Http.expectString Posted
                        }

                Nothing ->
                    -- TODO: Show 'required' message
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
                            let
                                debugText =
                                    "An error occurred: "
                                        ++ httpErrToString error
                            in
                            { modelLoading | debugText = debugText }
            in
            ( newModel, getRecentPostsCmd user )

        ClickedLike post ->
            ( model
            , Http.post
                { url = "api/posts/" ++ String.fromInt post.id ++ "/likes"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "user" user.name
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
                        [ Url.Builder.string "user" user.name
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
                    ( model, getRecentPostsCmd user )

                Err err ->
                    ( { model | debugText = httpErrToString err }, Cmd.none )


httpErrToString : Http.Error -> String
httpErrToString err =
    case err of
        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadBody _ ->
            "BadBody"

        Http.BadStatus code ->
            "Bad Status ("
                ++ String.fromInt code
                ++ ")"

        Http.BadUrl _ ->
            "Bad Url"


getRecentPostsCmd : Auth.User -> Cmd Msg
getRecentPostsCmd user =
    Http.get
        { url =
            custom Relative
                [ "api", "posts" ]
                [ Url.Builder.string "current_user" user.name ]
                Nothing
        , expect = Http.expectJson GotPosts (list postDecoder)
        }



-- VIEW


view : Auth.User -> Model -> View Msg
view user model =
    { title = "Feed"
    , body =
        UI.layout Route.Feed
            (Just user)
            [ div []
                [ span [] [ text model.debugText ]
                , viewPostForm model
                , div
                    []
                    (case model.status of
                        Loading ->
                            [ div [] [ text "Loading recent posts..." ] ]

                        _ ->
                            []
                                ++ List.map viewPost model.posts
                    )
                ]
            ]
    }


viewPost : Post -> Html Msg
viewPost post =
    let
        likes =
            if post.likeCount == 1 then
                "1 like"

            else
                String.fromInt post.likeCount ++ " likes"
    in
    div [ class "post" ]
        [ img [ class "post-image", src post.imgUrl ] []
        , span [ class "user" ] [ text post.user ]
        , span [ class "date" ] [ text (" on " ++ post.created) ]
        , div [ class "post-text" ] [ text post.text ]
        , div [ class "likes" ]
            [ img
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
            , span [] [ text likes ]
            ]
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
    form [ class "post", onSubmit ClickedPost ]
        [ div
            []
            [ button [ class "small", onClick PickPhoto ] [ text "Select Photo" ]
            , span [] [ text photo ]
            , input [ type_ "hidden", Html.Attributes.required True ] []
            ]
        , emptyDiv
        , div []
            [ textarea
                [ id "text"
                , rows 3
                , onInput ChangedPostText
                , placeholder "Write something..."
                , value model.postFormData.text
                ]
                []
            ]
        , emptyDiv
        , button
            []
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
        |> required "like_count" int
        |> required "img_url" string
