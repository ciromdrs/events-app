module FeedTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Pages.Feed exposing (Msg, viewPost)
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
            , likeCount = 0
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
        , testRenderPostField "0 likes"
            post
            [ tag "span", class "likes", text "0 likes" ]
        , testRenderPostField "1 like"
            { post | likeCount = 1 }
            [ tag "span", class "likes", text "1 like" ]
        , testRenderPostField "2 likes"
            { post | likeCount = 2 }
            [ tag "span", class "likes", text "2 likes" ]
        ]


testRenderPostField description post contents =
    test description <|
        \_ ->
            viewPost post
                |> Query.fromHtml
                |> Query.has contents
