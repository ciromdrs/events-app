module FeedTests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Pages.Feed exposing (..)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, classes, id, tag, text)


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


testEventsPane : Test
testEventsPane =
    let
        model =
            emptyModel

        loadingEvents =
            { posts = False
            , events = True
            }

        e1 : Event
        e1 =
            { id = 1, name = "Event 1" }

        e2 : Event
        e2 =
            { id = 2, name = "Event 2" }
    in
    describe "Events sidebar"
        [ describe "Loading message"
            [ testLoadingMessage "Renders loading message"
                { model | isLoading = loadingEvents }
                (Query.has [ text "Loading events..." ])
            , testLoadingMessage "Does not render loading message"
                model
                (Query.hasNot [ text "Loading events..." ])
            ]
        , describe "`current` class"
            [ testCurrentClass "Assigns `current` class to `All`"
                { model | events = [ e1, e2 ], selectedEvent = Nothing }
                [ class "current" ]
                "All"
            , testCurrentClass
                "Assigns `current` class to selected event filter"
                { model
                    | events = [ e1, e2 ]
                    , selectedEvent = Just ( e1, emptyFormData )
                }
                [ class "current" ]
                e1.name
            ]
        , eventsPaneTestCase "Renders new event form"
            model
            (Query.has [ tag "form", id "new-event" ])
        , eventsPaneTestCase "Event list is y-scrollable"
            model
            (Query.has [ tag "div", id "new-event" ])
        ]


eventsPaneTestCase description model query =
    test description <|
        \_ ->
            viewEventsPane model
                |> Query.fromHtml
                |> query


testLoadingMessage description model query =
    -- TODO: Delete this and use eventsPaneTestCase instead
    test description <|
        \_ ->
            viewEventsPane model
                |> Query.fromHtml
                |> query


testCurrentClass description model criteria name =
    -- TODO: Refactor this to use eventsPaneTestCase
    test description <|
        \_ ->
            viewEventsPane model
                |> Query.fromHtml
                |> Query.find [ id "events" ]
                |> Query.find criteria
                |> Query.has [ text name ]


testViewFeed : Test
testViewFeed =
    let
        model =
            emptyModel
    in
    describe "Feed"
        [ testRenderPostForm "Renders PostForm if selected event" model 0
        , testRenderPostForm "Does not render PostForm if not selected event"
            { model
                | selectedEvent =
                    Just ( { id = 1, name = "Test Event" }, emptyFormData )
            }
            1
        ]


testRenderPostForm description model count =
    test description <|
        \_ ->
            viewFeed model
                |> Query.fromHtml
                |> Query.findAll [ tag "form", class "post" ]
                |> Query.count (Expect.equal count)
