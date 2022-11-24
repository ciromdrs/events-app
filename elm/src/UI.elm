module UI exposing (h1, layout)

import Auth
import Gen.Route as Route exposing (Route)
import Html exposing (Html)
import Html.Attributes as Attr


layout : Route -> Maybe Auth.User -> List (Html msg) -> List (Html msg)
layout currentRoute maybeUser children =
    let
        viewLink : String -> Route -> Html msg
        viewLink label route =
            Html.a
                [ Attr.class "nav-link"
                , Attr.classList [ ( "current", route == currentRoute ) ]
                , Attr.href (Route.toHref route)
                ]
                [ Html.text label ]
    in
    Html.nav []
        (case maybeUser of
            Nothing ->
                []

            Just user ->
                [ viewLink "Feed" Route.Feed
                , viewLink user.name Route.Profile
                ]
        )
        :: [ Html.div [ Attr.class "page-content" ] children ]


h1 : String -> Html msg
h1 label =
    Html.h1 [] [ Html.text label ]
