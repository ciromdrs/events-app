module UI exposing (h1, layout)

import Auth
import Gen.Route as Route exposing (Route)
import Html exposing (Html)
import Html.Attributes as Attr


layout : Maybe Auth.User -> List (Html msg) -> List (Html msg)
layout maybeUser children =
    let
        viewLink : String -> Route -> Html msg
        viewLink label route =
            Html.a [ Attr.class "nav-link", Attr.href (Route.toHref route) ] [ Html.text label ]

        privateLinks : List (Html msg)
        privateLinks =
            case maybeUser of
                Nothing ->
                    [ viewLink "Sign in" Route.SignIn ]

                Just user ->
                    [ viewLink "Feed" Route.Feed
                    , viewLink user.name Route.Profile
                    ]
    in
    [ Html.div [ Attr.style "margin" "2rem" ]
        [ Html.header [ Attr.style "margin-bottom" "1rem" ]
            ([ Html.strong [ Attr.style "margin-right" "1rem" ]
                [ viewLink "Home" Route.Home_ ]
             ]
                ++ privateLinks
            )
        , Html.main_ [] children
        ]
    ]


h1 : String -> Html msg
h1 label =
    Html.h1 [] [ Html.text label ]
