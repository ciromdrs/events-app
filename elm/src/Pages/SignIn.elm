module Pages.SignIn exposing (Model, Msg, page)

import Gen.Params.SignIn exposing (Params)
import Html
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Page
import Request
import Shared
import Storage exposing (Storage)
import UI
import Url exposing (Url)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init
        , update = update shared.storage
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { name : String
    }


init : ( Model, Cmd Msg )
init =
    ( { name = "" }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ChangedName String
    | SubmittedSignInForm
    | SignInResponse (Result Http.Error String)


update : Storage -> Msg -> Model -> ( Model, Cmd Msg )
update storage msg model =
    case msg of
        ChangedName name ->
            ( { model | name = name }
            , Cmd.none
            )

        SubmittedSignInForm ->
            ( model
            , Http.post
                { url = "/api/session"
                , body =
                    Http.multipartBody
                        [ Http.stringPart "username" model.name ]
                , expect = Http.expectString SignInResponse
                }
            )

        SignInResponse result ->
            case result of
                Err err ->
                    -- TODO: Show error message
                    ( model, Cmd.none )

                Ok token ->
                    -- TODO: Store token
                    ( model
                    , Storage.signIn { name = model.name } storage
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Sign in"
    , body =
        [ Html.form [ Attr.class "login-form form", Events.onSubmit SubmittedSignInForm ]
            [ Html.input
                [ Attr.value model.name
                , Events.onInput ChangedName
                , Attr.placeholder "Username"
                ]
                []
            , Html.button [ Attr.disabled (String.isEmpty model.name) ]
                [ Html.text "Sign in" ]
            ]
        ]
    }
