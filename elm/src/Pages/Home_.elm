module Pages.Home_ exposing (Model, Msg, page, view)

import Auth
import Gen.Route as Route
import Html
import Html.Events as Events
import Page
import Request exposing (Request)
import Shared
import Storage exposing (Storage)
import UI
import View exposing (View)


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init
        , update = update shared.storage
        , view = view shared.storage.user
        , subscriptions = \_ -> Sub.none
        }



-- INIT


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



-- UPDATE


type Msg
    = None


update : Storage -> Msg -> Model -> ( Model, Cmd Msg )
update storage msg model =
    ( model, Cmd.none )


view : Maybe Auth.User -> Model -> View Msg
view maybeUser _ =
    { title = "Homepage"
    , body =
        UI.layout Route.Home_
            maybeUser
            [ Html.h1 [] [ Html.text "Hello, this is the Events App!" ]
            ]
    }
