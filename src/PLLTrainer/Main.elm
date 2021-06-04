module PLLTrainer.Main exposing (Model, Msg, page)

import Algorithm
import Cube exposing (Cube)
import PLL
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.States.TestRunning
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Ports
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
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TransitionMsg transition ->
            case transition of
                GetReadyForTest ->
                    let
                        ( _, stateCmd ) =
                            (states shared).getReadyScreen.init
                    in
                    ( { model | trainerState = GetReadyScreen }, stateCmd )

                StartTest ->
                    let
                        ( stateModel, stateCmd ) =
                            (states shared).testRunning.init
                    in
                    ( { model | trainerState = TestRunning stateModel }, stateCmd )

        LocalMsg typeOfLocalMsg ->
            case ( typeOfLocalMsg, model.trainerState ) of
                ( TestRunningMsg localMsg, TestRunning localModel ) ->
                    (states shared).testRunning.update localMsg localModel
                        |> Tuple.mapFirst
                            (\newTrainerState ->
                                { model | trainerState = TestRunning newTrainerState }
                            )

                _ ->
                    ( model, Ports.logError "Unexpected" )


type TransitionMsg
    = GetReadyForTest
    | StartTest


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning PLLTrainer.States.TestRunning.Model


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type Msg
    = TransitionMsg TransitionMsg
    | LocalMsg LocalMessage
    | NoOp


type LocalMessage
    = TestRunningMsg PLLTrainer.States.TestRunning.Msg


type InternalMsg
    = Placeholder


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        stateView =
            case model.trainerState of
                StartPage ->
                    (states shared).startPage.view ()

                GetReadyScreen ->
                    (states shared).getReadyScreen.view ()

                TestRunning stateModel ->
                    (states shared).testRunning.view stateModel

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle stateView


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    case model.trainerState of
        StartPage ->
            (states shared).startPage.subscriptions

        GetReadyScreen ->
            (states shared).getReadyScreen.subscriptions

        TestRunning _ ->
            (states shared).testRunning.subscriptions


states :
    Shared.Model
    ->
        { startPage : State () ()
        , getReadyScreen : State () ()
        , testRunning : State PLLTrainer.States.TestRunning.Msg PLLTrainer.States.TestRunning.Model
        }
states shared =
    { startPage =
        let
            state =
                PLLTrainer.States.StartPage.state
                    shared
                    { startTest = TransitionMsg GetReadyForTest
                    , noOp = NoOp
                    }
        in
        { init = ( (), Cmd.none )
        , view = always <| state.view
        , subscriptions = state.subscriptions
        , update = \_ _ -> ( (), Cmd.none )
        }
    , getReadyScreen =
        { init =
            ( ()
            , Task.perform
                (always <| TransitionMsg StartTest)
                (Process.sleep 1000)
            )
        , view = always <| PLLTrainer.States.GetReadyScreen.state shared
        , subscriptions = Sub.none
        , update = \_ _ -> ( (), Cmd.none )
        }
    , testRunning =
        let
            state =
                PLLTrainer.States.TestRunning.state
                    shared
                    (Tuple.first init).currentTestCase
                    (LocalMsg << TestRunningMsg)
        in
        { init = ( state.init, Cmd.none )
        , view = state.view
        , subscriptions = state.subscriptions
        , update = \msg model -> Tuple.pair (state.update msg model) Cmd.none
        }
    }


type alias State msg model =
    { init : ( model, Cmd Msg )
    , view : model -> StatefulPage.StateView Msg
    , subscriptions : Sub Msg
    , update : msg -> model -> ( model, Cmd Msg )
    }
