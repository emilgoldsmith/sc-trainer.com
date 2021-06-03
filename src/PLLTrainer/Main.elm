module PLLTrainer.Main exposing (Model, Msg, page)

import PLLTrainer.States.StartPage
import Page
import Shared
import StatefulPage
import View exposing (View)


page : Shared.Model -> Page.With Model Msg
page shared =
    Page.element
        { init = ( StartPage, Cmd.none )
        , update = \_ _ -> ( StartPage, Cmd.none )
        , view = view shared
        , subscriptions = subscriptions shared
        }


type Transition
    = StartTest


type TrainerState
    = StartPage


type alias Model =
    TrainerState


type Msg
    = Transition Transition
    | NoOp


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        state =
            getState shared model

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle state.view


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    let
        state =
            getState shared model
    in
    state.subscriptions


getState : Shared.Model -> Model -> { view : StatefulPage.StateView Msg, subscriptions : Sub Msg }
getState shared model =
    case model of
        StartPage ->
            PLLTrainer.States.StartPage.state shared { startTest = Transition StartTest, noOp = NoOp }
