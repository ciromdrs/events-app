module UsersTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, id, tag, text)
import Url exposing (Url)
import Users


exampleUrl : Url
exampleUrl =
    { protocol = Url.Http -- TODO: Change to HTTPS in the future
    , host = "localhost"
    , port_ = Just 80
    , path = "/some/path"
    , query = Just "arg1=val1&arg2=val2"
    , fragment = Just "some-fragment"
    }


exampleModel : Users.Model
exampleModel =
    { username = "usr1"
    , password = "pwd1"
    , token = Nothing
    , errMsg = ""
    , redirectUrl = exampleUrl
    }


testRendersRedirectUrl : Test
testRendersRedirectUrl =
    let
        model =
            exampleModel

        url =
            "http://localhost:80/some/path?arg1=val1&arg2=val2#some-fragment"
    in
    test "Renders the redirect url" <|
        \_ ->
            Users.view model
                |> Query.fromHtml
                |> Query.find [ tag "span", class "url" ]
                |> Query.has [ text url ]


testEmptiesPassword : Test
testEmptiesPassword =
    let
        model =
            exampleModel
    in
    test "Clicking `Log in` empties the password (only)." <|
        \_ ->
            Users.update Users.ClickedLogin model
                |> Tuple.first
                |> Expect.equal { model | password = "" }


testRendersNoErrorMessage : Test
testRendersNoErrorMessage =
    test "Renders no error message if it is empty." <|
        \_ ->
            Users.view { exampleModel | errMsg = "" }
                |> Query.fromHtml
                |> Query.findAll [ tag "span", class "error-message" ]
                |> Query.count (Expect.equal 0)


testRendersErrorMessage : Test
testRendersErrorMessage =
    let
        exErrMessage =
            "Example error message."

        model =
            { exampleModel | errMsg = exErrMessage }
    in
    test "Renders error messages." <|
        \_ ->
            Users.view model
                |> Query.fromHtml
                |> Query.find [ tag "span", class "error-message" ]
                |> Query.has [ text exErrMessage ]
