module Pages.Feed exposing (Model, Msg, page, viewPost)

import Auth
import Browser
import File exposing (File)
import File.Select as Select
import Gen.Params.Feed exposing (Params)
import Gen.Route as Route
import Html exposing (Attribute, Html, button, div, form, img, input, main_, span, text, textarea)
import Html.Attributes as Attr exposing (class, classList, id, placeholder, rows, src, style, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit, preventDefaultOn)
import Http
import Json.Decode as Decode exposing (Decoder, bool, int, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Page
import Request exposing (Request)
import Shared
import Task
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
        emptyModel =
            { debugText = ""
            , isLoading =
                { posts = False
                , events = False
                }
            , posts = []
            , events = []
            , selectedEvent = Nothing
            , postFormData = emptyFormData
            }

        ( getPostsModel, postsCmd ) =
            getRecentPostsCmd user emptyModel

        ( getPostsEventsModel, eventsCmd ) =
            getEventsCmd user getPostsModel

        model =
            getPostsEventsModel
    in
    ( model
    , Cmd.batch [ postsCmd, eventsCmd ]
    )


emptyFormData : FormData
emptyFormData =
    { text = "", photo = Nothing, hover = False, preview = Nothing }



-- MODEL


type alias Model =
    { debugText : String
    , isLoading : LoadingStatus
    , posts : List Post
    , events : List Event
    , selectedEvent : Maybe Event
    , postFormData : FormData
    }


type alias FormData =
    { text : String
    , photo : Maybe File
    , hover : Bool
    , preview : Maybe String
    }


type alias LoadingStatus =
    { posts : Bool
    , events : Bool
    }


type alias Post =
    { id : Int
    , user : String
    , text : String
    , created : String
    , likedByCurrentUser : Bool
    , likeCount : Int
    , imgUrl : String
    }


type alias Event =
    { name : String
    }



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List Post))
    | ClickedPost
    | ClickedCancel
    | Posted (Result Http.Error String)
    | ChangedPostText String
    | ChangedPostPhoto File
    | PickPhoto
    | DragEnter
    | DragLeave
    | GotPreview String
    | ClickedLike Post
    | ClickedDislike Post
    | LikedDisliked (Result Http.Error String)
    | GotEvents (Result Http.Error (List Event))
    | SelectedEvent (Maybe Event)


update : Auth.User -> Msg -> Model -> ( Model, Cmd Msg )
update user msg model =
    let
        formData =
            model.postFormData
    in
    case msg of
        GotPosts result ->
            let
                oldStatus =
                    model.isLoading

                newStatus =
                    { oldStatus | posts = False }

                newModel =
                    { model | isLoading = newStatus }
            in
            case result of
                Ok posts ->
                    ( { newModel | posts = posts }, Cmd.none )

                Err err ->
                    case err of
                        Http.BadBody errMessage ->
                            ( { newModel | debugText = errMessage }, Cmd.none )

                        _ ->
                            ( { newModel | debugText = "Unknown error" }
                            , Cmd.none
                            )

        ChangedPostText new ->
            let
                newData =
                    { formData | text = new }
            in
            ( { model | postFormData = newData }, Cmd.none )

        ChangedPostPhoto new ->
            let
                newData =
                    { formData | hover = False, photo = Just new }
            in
            ( { model | postFormData = newData }
            , Task.perform GotPreview <| File.toUrl new
            )

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

        ClickedCancel ->
            ( { model | postFormData = emptyFormData }
            , Cmd.none
            )

        Posted result ->
            let
                newModel =
                    case result of
                        Ok value ->
                            { model | postFormData = emptyFormData }

                        Err error ->
                            let
                                debugText =
                                    "An error occurred: "
                                        ++ httpErrToString error
                            in
                            { model | debugText = debugText }
            in
            getRecentPostsCmd user newModel

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
                    getRecentPostsCmd user model

                Err err ->
                    ( { model | debugText = httpErrToString err }, Cmd.none )

        DragEnter ->
            let
                newData =
                    { formData | hover = True }
            in
            ( { model | postFormData = newData }
            , Cmd.none
            )

        DragLeave ->
            let
                newData =
                    { formData | hover = False }
            in
            ( { model | postFormData = newData }
            , Cmd.none
            )

        GotPreview url ->
            let
                newData =
                    { formData | preview = Just url }
            in
            ( { model | postFormData = newData }
            , Cmd.none
            )

        GotEvents result ->
            let
                oldStatus =
                    model.isLoading

                newStatus =
                    { oldStatus | events = False }

                newModel =
                    { model | isLoading = newStatus }
            in
            case result of
                Ok events ->
                    ( { newModel | events = events }, Cmd.none )

                Err err ->
                    case err of
                        Http.BadBody errMessage ->
                            ( { newModel | debugText = errMessage }, Cmd.none )

                        _ ->
                            ( { newModel | debugText = "Unknown error" }
                            , Cmd.none
                            )

        SelectedEvent event ->
            ( { model | selectedEvent = event }
            , Cmd.none
            )


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


getRecentPostsCmd : Auth.User -> Model -> ( Model, Cmd Msg )
getRecentPostsCmd user model =
    let
        oldStatus =
            model.isLoading

        newStatus =
            { oldStatus | posts = True }
    in
    ( { model | isLoading = newStatus }
    , Http.get
        { url =
            custom Relative
                [ "api", "posts" ]
                [ Url.Builder.string "current_user" user.name ]
                Nothing
        , expect = Http.expectJson GotPosts (Decode.list postDecoder)
        }
    )


getEventsCmd : Auth.User -> Model -> ( Model, Cmd Msg )
getEventsCmd user model =
    let
        oldStatus =
            model.isLoading

        newStatus =
            { oldStatus | events = True }
    in
    ( { model | isLoading = newStatus }
    , Http.get
        { url =
            custom Relative
                [ "api", "events" ]
                [ Url.Builder.string "current_user" user.name ]
                Nothing
        , expect = Http.expectJson GotEvents (Decode.list eventDecoder)
        }
    )



-- VIEW


view : Auth.User -> Model -> View Msg
view user model =
    { title = "Feed"
    , body =
        UI.layout Route.Feed
            (Just user)
            [ viewEventsPane model
            , div [ class "feed" ]
                [ span [] [ text model.debugText ]
                , viewPostForm model
                , div
                    []
                    (if model.isLoading.posts then
                        [ div [] [ text "Loading recent posts..." ] ]

                     else
                        List.map viewPost model.posts
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
    Html.form [ class "post", onSubmit ClickedPost ]
        [ viewPhotoInput model.postFormData
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
        , button
            [ class "primary" ]
            [ text "Post" ]
        , if model.postFormData /= emptyFormData then
            button [ class "secondary", onClick ClickedCancel ]
                [ text "Cancel" ]

          else
            div [] []
        ]


viewPhotoInput : FormData -> Html Msg
viewPhotoInput formData =
    let
        photo =
            case formData.photo of
                Just photoFile ->
                    File.name photoFile

                Nothing ->
                    ""
    in
    case formData.preview of
        Nothing ->
            div
                [ class "dragdrop"
                , Attr.classList [ ( "hover", formData.hover ) ]
                , onClick PickPhoto
                , hijackOn "dragenter" (Decode.succeed DragEnter)
                , hijackOn "dragover" (Decode.succeed DragEnter)
                , hijackOn "dragleave" (Decode.succeed DragLeave)
                , hijackOn "drop" dropDecoder
                ]
                [ span [] [ text "Drag and drop or click to " ]
                , button [ class "small primary" ] [ text "Select Photo" ]
                , span [] [ text photo ]
                ]

        Just url ->
            viewPreview url


viewPreview : String -> Html msg
viewPreview url =
    img [ class "post-image", src url ] []


viewEventsPane : Model -> Html Msg
viewEventsPane model =
    let
        filter : ( String, Bool, Msg ) -> Html Msg
        filter ( label, current, onClickMsg ) =
            div
                [ class "event"
                , classList [ ( "current", current ) ]
                , onClick onClickMsg
                ]
                [ text label ]

        eventMap : Event -> ( String, Bool, Msg )
        eventMap event =
            ( event.name
            , Just event == model.selectedEvent
            , SelectedEvent (Just event)
            )
    in
    div
        [ class "events-side-pane" ]
        ([ span
            [ class "title" ]
            [ text "My Events" ]
         ]
            ++ (if model.isLoading.events then
                    [ text "Loading events..." ]

                else
                    filter
                        ( "All"
                        , model.selectedEvent == Nothing
                        , SelectedEvent Nothing
                        )
                        :: List.map
                            filter
                            (List.map eventMap model.events)
               )
        )


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


eventDecoder : Decoder Event
eventDecoder =
    succeed Event
        |> required "name" string


dropDecoder : Decoder Msg
dropDecoder =
    Decode.at [ "dataTransfer", "files" ] (Decode.oneOrMore (\one more -> ChangedPostPhoto one) File.decoder)


hijackOn : String -> Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (Decode.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )
