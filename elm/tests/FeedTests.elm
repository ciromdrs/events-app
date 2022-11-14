module FeedTests exposing (..)

import Expect exposing (Expectation)
import Feed exposing (Msg, Post, viewPost)
import Fuzz exposing (Fuzzer, int, list, string)
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
            , imgUrl = "fake/url"
            }

        likedPost =
            { post | likedByCurrentUser = True }
    in
    describe "Renders a Post"
        [ testRenderPostField "image field"
            post
            [ tag "img", class "post-image" ]
        , testRenderPostField "user field"
            post
            [ tag "div", class "user", text "user1" ]
        , testRenderPostField "text field"
            post
            [ tag "div", class "post-text", text "some text..." ]
        , testRenderPostField "created field"
            post
            [ tag "span", class "date", text "2022-11-04 23:53:22" ]
        , testRenderPostField "like button"
            post
            [ tag "img", class "like-button" ]
        , testRenderPostField "dislike button"
            likedPost
            [ tag "img", class "dislike-button" ]
        ]


testRenderPostField description post contents =
    test description <|
        \_ ->
            viewPost post
                |> Query.fromHtml
                |> Query.has contents
