module PhotoGalleryTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main exposing (Msg, Post, viewPost)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)


testViewPost : Test
testViewPost =
    let
        post =
            { id = 1
            , user = "user1"
            , text = "some text..."
            , created = "2022-11-04 23:53:22"
            }
    in
    describe "Renders a Post"
        [ testRenderPostField "id field" post [ text "1" ]
        , testRenderPostField "user field" post [ text "user1" ]
        , testRenderPostField "text field" post [ text "some text..." ]
        , testRenderPostField "created field" post [ text "2022-11-04 23:53:22" ]
        ]


testRenderPostField description post contents =
    test description <|
        \_ ->
            viewPost post
                |> Query.fromHtml
                |> Query.has contents
