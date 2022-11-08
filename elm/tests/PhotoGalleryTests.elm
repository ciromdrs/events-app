module PhotoGalleryTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main exposing (Msg, Post, viewPost)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, tag, text)


testViewPost : Test
testViewPost =
    let
        post =
            { id = 1
            , user = "user1"
            , text = "some text..."
            , created = "2022-11-04 23:53:22"
            , likedByCurrentUser = False
            }
    in
    describe "Renders a Post"
        [ testRenderPostField "user field" post [ tag "div", class "post-user", text "user1" ]
        , testRenderPostField "text field" post [ tag "div", class "post-text", text "some text..." ]
        , testRenderPostField "created field" post [ tag "span", class "post-date", text "2022-11-04 23:53:22" ]
        , testRenderPostField "like button" post [ tag "img", class "like-button" ] -- Test whether it is a like or a dislike button
        ]


testRenderPostField description post contents =
    test description <|
        \_ ->
            viewPost post
                |> Query.fromHtml
                |> Query.has contents
