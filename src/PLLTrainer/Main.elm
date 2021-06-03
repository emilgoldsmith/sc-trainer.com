module PLLTrainer.Main exposing (Model, Msg, page)

import Algorithm
import Cube exposing (Cube)
import PLL
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.States.TestRunning
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Process
import Shared
import StatefulPage
import Task
import View exposing (View)


page : Shared.Model -> Page.With Model Msg
page shared =
    Page.element
        { init = init
        , update = update shared
        , view = view shared
        , subscriptions = subscriptions shared
        }


init : ( Model, Cmd Msg )
init =
    ( { trainerState = StartPage
      , expectedCubeState = Cube.solved

      -- This is just a placeholder as new test cases are always generated
      -- just before the test is run, and this way we avoid a more complex
      -- type that for example needs to represent that there's no test case
      -- until after the first getReadyScreen is done which would then
      -- possibly need a Maybe or a difficult tagged type. A placeholder
      -- seems the best option of these right now
      , currentTestCase = ( Algorithm.empty, PLL.Aa, Algorithm.empty )
      }
    , Cmd.none
    )


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    let
        state =
            getState shared model.trainerState
    in
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Transition transition ->
            doTransition shared model transition


doTransition : Shared.Model -> Model -> Transition -> ( Model, Cmd Msg )
doTransition shared model transition =
    let
        nextTrainerState =
            case transition of
                GetReadyForTest ->
                    GetReadyScreen

                StartTest ->
                    TestRunning

        nextState =
            getState shared nextTrainerState
    in
    ( { model | trainerState = nextTrainerState }, Tuple.second nextState.init )


type Transition
    = GetReadyForTest
    | StartTest


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type Msg
    = Transition Transition
    | NoOp


type InternalMsg
    = Placeholder


type alias StateModel =
    ()


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        state =
            getState shared model.trainerState

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle state.view


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    let
        state =
            getState shared model.trainerState
    in
    state.subscriptions


getState :
    Shared.Model
    -> TrainerState
    -> State StateModel
getState shared trainerState =
    case trainerState of
        StartPage ->
            let
                state =
                    PLLTrainer.States.StartPage.state
                        shared
                        { startTest = Transition GetReadyForTest
                        , noOp = NoOp
                        }
            in
            { init = ( (), Cmd.none )
            , view = state.view
            , subscriptions = state.subscriptions
            }

        GetReadyScreen ->
            { init =
                ( ()
                , Task.perform
                    (always <| Transition StartTest)
                    (Process.sleep 1000)
                )
            , view = PLLTrainer.States.GetReadyScreen.state shared
            , subscriptions = Sub.none
            }

        TestRunning ->
            { init = ( (), Cmd.none )
            , view = PLLTrainer.States.TestRunning.state shared
            , subscriptions = Sub.none
            }


type alias State model =
    { init : ( model, Cmd Msg )
    , view : StatefulPage.StateView Msg
    , subscriptions : Sub Msg
    }
