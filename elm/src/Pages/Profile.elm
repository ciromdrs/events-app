module Pages.Profile exposing (Model, Msg, page)

import Auth
import Gen.Params.SignOut exposing (Params)
import Gen.Route as Route
import Html exposing (button, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Page
import Request exposing (Request)
import Shared
import Storage exposing (Storage)
import UI
import View exposing (View)



-- MAIN


type alias Model =
    {}


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.protected.element <|
        \user ->
            { init = ( {}, Cmd.none )
            , update = update shared.storage
            , view = view user
            , subscriptions = \_ -> Sub.none
            }



-- UPDATE


type Msg
    = ClickedSignOut


update : Storage -> Msg -> Model -> ( Model, Cmd Msg )
update storage msg model =
    case msg of
        ClickedSignOut ->
            ( model
            , Storage.signOut storage
            )



-- VIEW


view : Auth.User -> Model -> View Msg
view user model =
    { title = "Profile"
    , body =
        UI.layout Route.Profile
            (Just user)
            [ div [] [ span [] [ text user.name ] ]
            , button [ onClick ClickedSignOut ] [ text "Sign out" ]
            ]
    }
