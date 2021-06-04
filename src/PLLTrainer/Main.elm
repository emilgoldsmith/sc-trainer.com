module PLLTrainer.Main exposing (Model, Msg, page)

import Algorithm
import Cube exposing (Cube)
import PLL
import PLLTrainer.States.EvaluateResult
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.States.TestRunning
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Ports
import Process
import Random
import Shared
import StatefulPage
import Task
import Time
import TimeInterval
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
                            (states shared model).getReadyScreen.init
                    in
                    ( { model | trainerState = GetReadyScreen }, stateCmd )

                StartTest ->
                    ( model
                    , Random.generate
                        (InternalMsg << GenerateStartTestData << TestCaseGenerated)
                        PLLTrainer.TestCase.generate
                    )

                EndTest ->
                    ( { model | trainerState = EvaluateResult }, Cmd.none )

        InternalMsg internalMsg ->
            case internalMsg of
                GenerateStartTestData (TestCaseGenerated testCase) ->
                    ( model
                    , Task.perform
                        (InternalMsg << GenerateStartTestData << EverythingGenerated testCase)
                        Time.now
                    )

                GenerateStartTestData (EverythingGenerated testCase startTime) ->
                    let
                        ( stateModel, stateCmd ) =
                            (states shared model).testRunning.init
                    in
                    ( { model
                        | trainerState = TestRunning stateModel startTime
                        , currentTestCase = testCase
                      }
                    , stateCmd
                    )

        StateMsg typeOfLocalMsg ->
            case ( typeOfLocalMsg, model.trainerState ) of
                ( TestRunningMsg localMsg, TestRunning localModel startTime ) ->
                    (states shared model).testRunning.update localMsg localModel
                        |> Tuple.mapFirst
                            (\newTrainerState ->
                                { model | trainerState = TestRunning newTrainerState startTime }
                            )

                _ ->
                    ( model, Ports.logError "Unexpected" )


type TransitionMsg
    = GetReadyForTest
    | StartTest
    | EndTest


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning PLLTrainer.States.TestRunning.Model Time.Posix
    | EvaluateResult


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type Msg
    = TransitionMsg TransitionMsg
    | StateMsg StateMsg
    | InternalMsg InternalMsg
    | NoOp


type StateMsg
    = TestRunningMsg PLLTrainer.States.TestRunning.Msg


type InternalMsg
    = GenerateStartTestData StartTestData


{-| We use this structure to make sure the test case
is generated before the start time, so we can ensure
we don't record the start time until the very last moment
-}
type StartTestData
    = TestCaseGenerated TestCase
    | EverythingGenerated TestCase Time.Posix


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        stateView =
            case model.trainerState of
                StartPage ->
                    (states shared model).startPage.view ()

                GetReadyScreen ->
                    (states shared model).getReadyScreen.view ()

                TestRunning stateModel _ ->
                    (states shared model).testRunning.view stateModel

                EvaluateResult ->
                    (states shared model).evaluateResult.view ()

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle stateView


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    case model.trainerState of
        StartPage ->
            (states shared model).startPage.subscriptions

        GetReadyScreen ->
            (states shared model).getReadyScreen.subscriptions

        TestRunning _ _ ->
            (states shared model).testRunning.subscriptions

        EvaluateResult ->
            (states shared model).evaluateResult.subscriptions


states :
    Shared.Model
    -> Model
    ->
        { startPage : State () ()
        , getReadyScreen : State () ()
        , testRunning : State PLLTrainer.States.TestRunning.Msg PLLTrainer.States.TestRunning.Model
        , evaluateResult : State () ()
        }
states shared model =
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
                    model.currentTestCase
                    (StateMsg << TestRunningMsg)
                    { endTest = TransitionMsg EndTest }
        in
        { init = ( state.init, Cmd.none )
        , view = state.view
        , subscriptions = state.subscriptions
        , update = \msg myModel -> Tuple.pair (state.update msg myModel) Cmd.none
        }
    , evaluateResult =
        let
            state =
                PLLTrainer.States.EvaluateResult.state
                    shared
                    { evaluateCorrect = NoOp
                    , evaluateWrong = NoOp
                    , noOp = NoOp
                    }
                    { expectedCubeState = model.expectedCubeState
                    , result = TimeInterval.zero
                    , transitionsDisabled = False
                    }
        in
        { init = ( (), Cmd.none )
        , view = always <| state.view
        , subscriptions = state.subscriptions
        , update = \_ _ -> ( (), Cmd.none )
        }
    }


type alias State msg model =
    { init : ( model, Cmd Msg )
    , view : model -> StatefulPage.StateView Msg
    , subscriptions : Sub Msg
    , update : msg -> model -> ( model, Cmd Msg )
    }
