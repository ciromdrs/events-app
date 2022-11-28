module Pages.Feed exposing (Event, Model, Msg, emptyFormData, emptyModel, page, viewEventsPane, viewFeed, viewPost)

import Auth
import Browser
import Dict exposing (Dict)
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
import Regex exposing (Regex)
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
    , events : List Event -- TODO: Use a Set Event instead
    , selectedEvent : Maybe ( Event, FormData ) -- TODO: Change to maybeEventFormData
    , eventNameInput : String
    , justCreatedEventId : Maybe Int
    }


emptyModel : Model
emptyModel =
    { debugText = ""
    , isLoading =
        { posts = False
        , events = False
        }
    , posts = []
    , events = []
    , selectedEvent = Nothing
    , eventNameInput = ""
    , justCreatedEventId = Nothing
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
    { id : Int
    , name : String
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
    | SelectedEvent (Maybe ( Event, FormData ))
    | ChangedEventName String
    | ClickedNewEvent
    | CreatedEvent (Result Http.Error String)


update : Auth.User -> Msg -> Model -> ( Model, Cmd Msg )
update user msg model =
    case ( msg, model.selectedEvent ) of
        ( GotPosts result, _ ) ->
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

        ( ChangedPostText new, Just ( event, formData ) ) ->
            let
                newData =
                    { formData | text = new }
            in
            ( { model | selectedEvent = Just ( event, newData ) }, Cmd.none )

        ( ChangedPostText _, Nothing ) ->
            ( model, Cmd.none )

        ( ChangedPostPhoto new, Just ( event, formData ) ) ->
            let
                newData =
                    { formData | hover = False, photo = Just new }
            in
            ( { model | selectedEvent = Just ( event, newData ) }
            , Task.perform GotPreview <| File.toUrl new
            )

        ( ChangedPostPhoto _, Nothing ) ->
            ( model, Cmd.none )

        ( PickPhoto, Just _ ) ->
            ( model
            , Select.file [ "image/*" ] ChangedPostPhoto
            )

        ( PickPhoto, Nothing ) ->
            ( model, Cmd.none )

        ( ClickedPost, Just ( event, formData ) ) ->
            ( model
            , case formData.photo of
                Just photo ->
                    Http.post
                        { url = "api/posts"
                        , body =
                            Http.multipartBody
                                [ Http.stringPart "user" user.name
                                , Http.stringPart "text" formData.text
                                , Http.filePart "photo" photo
                                , Http.stringPart "event"
                                    (String.fromInt event.id)
                                ]
                        , expect = Http.expectString Posted
                        }

                Nothing ->
                    -- TODO: Show 'required' message
                    Cmd.none
            )

        ( ClickedPost, Nothing ) ->
            ( model, Cmd.none )

        ( ClickedCancel, Just ( event, formData ) ) ->
            ( { model | selectedEvent = Just ( event, emptyFormData ) }
            , Cmd.none
            )

        ( ClickedCancel, Nothing ) ->
            ( model, Cmd.none )

        ( Posted result, Just ( event, _ ) ) ->
            let
                newModel =
                    case result of
                        Ok value ->
                            { model | selectedEvent = Just ( event, emptyFormData ) }

                        Err error ->
                            let
                                debugText =
                                    "An error occurred: "
                                        ++ httpErrToString error
                            in
                            { model | debugText = debugText }
            in
            getRecentPostsCmd user newModel

        ( Posted _, Nothing ) ->
            ( model, Cmd.none )

        ( ClickedLike post, _ ) ->
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

        ( ClickedDislike post, _ ) ->
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

        ( LikedDisliked result, _ ) ->
            case result of
                Ok _ ->
                    getRecentPostsCmd user model

                Err err ->
                    ( { model | debugText = httpErrToString err }, Cmd.none )

        ( DragEnter, Just ( event, formData ) ) ->
            let
                newData =
                    { formData | hover = True }
            in
            ( { model | selectedEvent = Just ( event, newData ) }
            , Cmd.none
            )

        ( DragEnter, Nothing ) ->
            ( model, Cmd.none )

        ( DragLeave, Just ( event, formData ) ) ->
            let
                newData =
                    { formData | hover = False }
            in
            ( { model | selectedEvent = Just ( event, newData ) }
            , Cmd.none
            )

        ( DragLeave, Nothing ) ->
            ( model, Cmd.none )

        ( GotPreview url, Just ( event, formData ) ) ->
            let
                newData =
                    { formData | preview = Just url }
            in
            ( { model | selectedEvent = Just ( event, newData ) }
            , Cmd.none
            )

        ( GotPreview _, Nothing ) ->
            ( model, Cmd.none )

        ( GotEvents result, _ ) ->
            let
                oldStatus =
                    model.isLoading

                newStatus =
                    { oldStatus | events = False }

                modelNotLoading =
                    { model | isLoading = newStatus }
            in
            case result of
                Ok events ->
                    let
                        modelWithEventsClearJustCreated =
                            { modelNotLoading
                                | events = events
                                , justCreatedEventId = Nothing
                            }

                        previousEvent =
                            {- Check whether the previous selected event is
                               still in the list of events.
                            -}
                            case model.selectedEvent of
                                Just ( event, formData ) ->
                                    case selectEvent event.id events of
                                        Just selected ->
                                            Just ( selected, formData )

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing
                    in
                    case ( modelNotLoading.justCreatedEventId, modelNotLoading.selectedEvent ) of
                        ( Just id, _ ) ->
                            case selectEvent id events of
                                Just event ->
                                    getRecentPostsCmd user
                                        { modelWithEventsClearJustCreated
                                            | selectedEvent = Just ( event, emptyFormData )
                                        }

                                Nothing ->
                                    {- Should not happen in practice, but even
                                       so, try to restore previously selected
                                       event.
                                    -}
                                    getRecentPostsCmd user
                                        { modelWithEventsClearJustCreated
                                            | selectedEvent = previousEvent
                                        }

                        ( Nothing, _ ) ->
                            getRecentPostsCmd user
                                { modelWithEventsClearJustCreated
                                    | selectedEvent = previousEvent
                                }

                Err err ->
                    ( { modelNotLoading | debugText = httpErrToString err }
                    , Cmd.none
                    )

        ( SelectedEvent maybeEventFormData, _ ) ->
            if maybeEventFormData /= model.selectedEvent then
                getRecentPostsCmd user
                    { model | selectedEvent = maybeEventFormData }

            else
                ( model, Cmd.none )

        ( ChangedEventName new, _ ) ->
            ( { model | eventNameInput = new }, Cmd.none )

        ( ClickedNewEvent, _ ) ->
            ( model
            , Http.post
                { url = "api/events"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "name" model.eventNameInput
                        , Http.stringPart "owner" user.name
                        ]
                , expect = expectLocation CreatedEvent
                }
            )

        ( CreatedEvent result, _ ) ->
            case result of
                Ok location ->
                    let
                        newModel =
                            { model | eventNameInput = "" }
                    in
                    case idFromLocation location of
                        Just id ->
                            getEventsCmd user
                                { newModel | justCreatedEventId = Just id }

                        Nothing ->
                            ( model, Cmd.none )

                Err error ->
                    ( { model
                        | debugText =
                            "Event creation error: "
                                ++ httpErrToString error
                      }
                    , Cmd.none
                    )


expectLocation : (Result Http.Error String -> Msg) -> Http.Expect Msg
expectLocation toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata body ->
                    case Dict.get "location" metadata.headers of
                        Nothing ->
                            Err (Http.BadBody "Missing location header")

                        Just url ->
                            Ok url


idFromLocation : String -> Maybe Int
idFromLocation location =
    let
        regex =
            Maybe.withDefault Regex.never <|
                Regex.fromString "\\d+$"

        matches =
            Regex.findAtMost 1 regex location
    in
    case matches of
        id :: [] ->
            String.toInt id.match

        _ ->
            Nothing


selectEvent : Int -> List Event -> Maybe Event
selectEvent id events =
    case List.partition (\event -> event.id == id) events of
        ( event :: [], _ ) ->
            Just event

        ( _, _ ) ->
            Nothing


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
                ([ Url.Builder.string "current_user" user.name ]
                    ++ (case model.selectedEvent of
                            Nothing ->
                                []

                            Just ( event, _ ) ->
                                [ Url.Builder.int "event" event.id ]
                       )
                )
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
            , viewFeed model
            ]
    }


viewFeed : Model -> Html Msg
viewFeed model =
    main_ []
        [ div [ class "feed" ]
            [ span [] [ text model.debugText ]
            , case model.selectedEvent of
                Just ( event, formData ) ->
                    viewPostForm formData

                Nothing ->
                    text ""
            , div
                []
                (if model.isLoading.posts then
                    [ div [] [ text "Loading recent posts..." ] ]

                 else
                    List.map viewPost model.posts
                )
            ]
        ]


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


viewPostForm : FormData -> Html Msg
viewPostForm formData =
    Html.form [ class "post", onSubmit ClickedPost ]
        [ viewPhotoInput formData
        , div []
            [ textarea
                [ id "text"
                , rows 3
                , onInput ChangedPostText
                , placeholder "Write something..."
                , value formData.text
                ]
                []
            ]
        , button
            [ class "primary" ]
            [ text "Post" ]
        , if formData /= emptyFormData then
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
            case model.selectedEvent of
                Just ( selected, formData ) ->
                    ( event.name
                    , event == selected
                    , SelectedEvent (Just ( event, formData ))
                    )

                Nothing ->
                    ( event.name
                    , False
                    , SelectedEvent (Just ( event, emptyFormData ))
                    )
    in
    div
        [ class "events-sidebar" ]
        (span
            [ class "title" ]
            [ text "My Events" ]
            :: viewEventForm model
            :: (if model.isLoading.events then
                    [ span [] [ text "Loading events..." ] ]

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


viewEventForm : Model -> Html Msg
viewEventForm model =
    form [ id "new-event", onSubmit ClickedNewEvent ]
        [ input
            [ placeholder "New event"
            , onInput ChangedEventName
            , value model.eventNameInput
            ]
            []
        , button [ class "primary" ] [ text "+" ]
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


eventDecoder : Decoder Event
eventDecoder =
    succeed Event
        |> required "id" int
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
