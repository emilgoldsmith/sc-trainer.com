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
                            ((states shared model).getReadyScreen ()).init
                    in
                    ( { model | trainerState = GetReadyScreen }, stateCmd )

                StartTest NothingGenerated ->
                    ( model
                    , Random.generate
                        (TransitionMsg << StartTest << TestCaseGenerated)
                        PLLTrainer.TestCase.generate
                    )

                StartTest (TestCaseGenerated testCase) ->
                    ( model
                    , Task.perform
                        (TransitionMsg << StartTest << EverythingGenerated testCase)
                        Time.now
                    )

                StartTest (EverythingGenerated testCase startTime) ->
                    let
                        arguments =
                            { startTime = startTime }

                        ( stateModel, stateCmd ) =
                            ((states shared model).testRunning arguments).init
                    in
                    ( { model
                        | trainerState = TestRunning stateModel arguments
                        , currentTestCase = testCase
                      }
                    , stateCmd
                    )

                EndTest _ ->
                    ( { model
                        | trainerState =
                            EvaluateResult
                                { expectedCubeState = model.expectedCubeState
                                , result = TimeInterval.zero
                                , transitionsDisabled = False
                                }
                      }
                    , Cmd.none
                    )

        StateMsg typeOfLocalMsg ->
            case ( typeOfLocalMsg, model.trainerState ) of
                ( TestRunningMsg localMsg, TestRunning localModel arguments ) ->
                    ((states shared model).testRunning arguments).update localMsg localModel
                        |> Tuple.mapFirst
                            (\newTrainerState ->
                                { model | trainerState = TestRunning newTrainerState arguments }
                            )

                _ ->
                    ( model, Ports.logError "Unexpected" )


type TransitionMsg
    = GetReadyForTest
    | StartTest StartTestData
    | EndTest { startTime : Time.Posix }


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning PLLTrainer.States.TestRunning.Model { startTime : Time.Posix }
    | EvaluateResult PLLTrainer.States.EvaluateResult.Arguments


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type Msg
    = TransitionMsg TransitionMsg
    | StateMsg StateMsg
    | NoOp


type StateMsg
    = TestRunningMsg PLLTrainer.States.TestRunning.Msg


{-| We use this structure to make sure the test case
is generated before the start time, so we can ensure
we don't record the start time until the very last moment
-}
type StartTestData
    = NothingGenerated
    | TestCaseGenerated TestCase
    | EverythingGenerated TestCase Time.Posix


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        stateView =
            case model.trainerState of
                StartPage ->
                    ((states shared model).startPage ()).view ()

                GetReadyScreen ->
                    ((states shared model).getReadyScreen ()).view ()

                TestRunning stateModel arguments ->
                    ((states shared model).testRunning arguments).view stateModel

                EvaluateResult arguments ->
                    ((states shared model).evaluateResult arguments).view ()

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle stateView


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    case model.trainerState of
        StartPage ->
            ((states shared model).startPage ()).subscriptions

        GetReadyScreen ->
            ((states shared model).getReadyScreen ()).subscriptions

        TestRunning _ arguments ->
            ((states shared model).testRunning arguments).subscriptions

        EvaluateResult arguments ->
            ((states shared model).evaluateResult arguments).subscriptions


states :
    Shared.Model
    -> Model
    ->
        { startPage : State () () ()
        , getReadyScreen : State () () ()
        , testRunning : State PLLTrainer.States.TestRunning.Msg PLLTrainer.States.TestRunning.Model { startTime : Time.Posix }
        , evaluateResult : State () () PLLTrainer.States.EvaluateResult.Arguments
        }
states shared model =
    { startPage =
        always <|
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
        always <|
            { init =
                ( ()
                , Task.perform
                    (always <| TransitionMsg (StartTest NothingGenerated))
                    (Process.sleep 1000)
                )
            , view = always <| PLLTrainer.States.GetReadyScreen.state shared
            , subscriptions = Sub.none
            , update = \_ _ -> ( (), Cmd.none )
            }
    , testRunning =
        \arguments ->
            let
                state =
                    PLLTrainer.States.TestRunning.state
                        shared
                        model.currentTestCase
                        (StateMsg << TestRunningMsg)
                        { endTest = TransitionMsg (EndTest arguments) }
            in
            { init = ( state.init, Cmd.none )
            , view = state.view
            , subscriptions = state.subscriptions
            , update = \msg myModel -> Tuple.pair (state.update msg myModel) Cmd.none
            }
    , evaluateResult =
        \arguments ->
            let
                state =
                    PLLTrainer.States.EvaluateResult.state
                        shared
                        { evaluateCorrect = NoOp
                        , evaluateWrong = NoOp
                        , noOp = NoOp
                        }
                        arguments
            in
            { init = ( (), Cmd.none )
            , view = always <| state.view
            , subscriptions = state.subscriptions
            , update = \_ _ -> ( (), Cmd.none )
            }
    }


type alias State msg model arguments =
    arguments
    ->
        { init : ( model, Cmd Msg )
        , view : model -> StatefulPage.StateView Msg
        , subscriptions : Sub Msg
        , update : msg -> model -> ( model, Cmd Msg )
        }
