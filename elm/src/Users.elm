module Users exposing (Model, Msg(..), init, update, userEncoder, view)

import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (class, id, name, placeholder, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task
import Url exposing (Url)
import Url.Builder exposing (relative)


type alias Model =
    { username : String
    , password : String
    , token : Maybe String
    , errMsg : String
    , redirectUrl : Url
    }


type Msg
    = ClickedLogin
    | ChangedUsername String
    | ChangedPassword String
    | Authenticated String Url
    | ReceivedResponse (Result Http.Error String)



-- INIT


init : () -> Url -> ( Model, Cmd Msg )
init () redirectUrl =
    ( { username = ""
      , password = ""
      , token = Nothing
      , errMsg = ""
      , redirectUrl = redirectUrl
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangedUsername new ->
            ( { model | username = new }, Cmd.none )

        ChangedPassword new ->
            ( { model | password = new }, Cmd.none )

        ClickedLogin ->
            ( { model | password = "" }
            , Http.post
                { url = "api/session"
                , body =
                    Http.jsonBody <| userEncoder model.username model.password
                , expect = Http.expectString ReceivedResponse
                }
            )

        ReceivedResponse result ->
            let
                cleanModel =
                    -- Remove private authentication information from model
                    { model | password = "", token = Nothing }
            in
            case result of
                Ok tokenStr ->
                    ( cleanModel
                    , trigger (Authenticated tokenStr model.redirectUrl)
                    )

                Err err ->
                    ( { cleanModel | errMsg = Debug.toString err }, Cmd.none )

        Authenticated token redirectUrl ->
            -- The parent page should intercept this message to get the token.
            Debug.log "This message should have been intercepted"
                ( model, Cmd.none )


userEncoder : String -> String -> Encode.Value
userEncoder username password =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "password", Encode.string password )
        ]


tokenDecoder : String -> Result Decode.Error String
tokenDecoder =
    Decode.decodeString Decode.string


trigger : msg -> Cmd msg
trigger msg =
    Task.succeed msg
        |> Task.perform identity



-- VIEW


view : Model -> Html Msg
view model =
    let
        errorMsg =
            if String.isEmpty model.errMsg then
                []

            else
                [ span [ class "error-message" ] [ text model.errMsg ] ]
    in
    div [ class "login-form form" ]
        ([ text "Log in to proceed to"
         , span [ class "url" ] [ text (Url.toString model.redirectUrl) ]
         ]
            ++ errorMsg
            ++ [ input [ placeholder "Username", onInput ChangedUsername ] []
               , input [ type_ "password", placeholder "Password", onInput ChangedPassword ] []
               , button [ id "login-button", onClick ClickedLogin ] [ text "Log In" ]
               ]
        )
