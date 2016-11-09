module State exposing (..)

import String
import Dict
import List.Extra
import Navigation
import UrlParser exposing (..)

import Types exposing (..)
import Rest


-- INIT

init : Result String Page -> (Model, Cmd Msg)
init result =
  let
    model = initialModel (pageFromResult result)
  in
    model !
      [ Rest.getData FetchFail FetchPostsSuccess Rest.decodePosts "data/posts.json"
      , Rest.getData FetchFail FetchCommentsSuccess Rest.decodeComments "data/comments.json"
      ]


-- UPDATE

update : Msg -> Model -> (Model, Cmd Msg)
update action model =
  case action of
    FetchPostsSuccess posts ->
      { model | posts = posts } ! []

    FetchCommentsSuccess comments ->
      { model | comments = comments } ! []

    FetchFail _ ->
      model ! []

    IncrementLikes code ->
      let
        incrementPostLikes : String -> Post -> Post
        incrementPostLikes code post =
          if post.code == code then
            { post | likes = post.likes + 1 }
          else
            post

        updatedPosts = List.map (incrementPostLikes code) model.posts
      in
        { model | posts = updatedPosts } ! []

    UpdateCommentUser user ->
      let
        comment = model.comment
        updatedComment = { comment | user = user }
      in
        { model | comment = updatedComment } ! []

    UpdateCommentText text ->
      let
        comment = model.comment
        updatedComment = { comment | text = text }
      in
        { model | comment = updatedComment } ! []

    AddComment code comment ->
      let
        addPostComment : Maybe (List Comment) -> Maybe (List Comment)
        addPostComment comments =
          case comments of
            Just comments ->
              Just (comments ++ [ comment ])

            Nothing ->
              Nothing

        updatedComments = Dict.update code addPostComment model.comments
      in
        { model
          | comments = updatedComments
          , comment = Comment "" ""
          } ! []

    RemoveComment code index ->
      let
        removePostComment : Maybe (List Comment) -> Maybe (List Comment)
        removePostComment comments =
          case comments of
            Just comments ->
              Just (List.Extra.removeAt index comments)

            Nothing ->
              Nothing

        updatedComments = Dict.update code removePostComment model.comments
      in
        { model | comments = updatedComments } ! []


-- URL UPDATE

urlUpdate : Result String Page -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  let
    page = pageFromResult result
  in
    { model | page = page } ! []


pageFromResult : Result String Page -> Page
pageFromResult result =
  case result of
    Ok page ->
      page

    Err _ ->
      Photos


toURL : Page -> String
toURL page =
  let
    baseUrl = "#/"
  in
    case page of
      Photos ->
        baseUrl

      Photo code ->
        baseUrl ++ "view/" ++ code


-- TODO: use location.pathname instead
hashParser : Navigation.Location -> Result String Page
hashParser location =
  UrlParser.parse identity pageParser (String.dropLeft 2 location.hash)


pageParser : Parser (Page -> a) a
pageParser =
  oneOf
    [ format Photos (s "")
    , format Photo (s "view" </> string)
    ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
