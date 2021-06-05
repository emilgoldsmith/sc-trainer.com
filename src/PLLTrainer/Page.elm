module PLLTrainer.Page exposing (Model, Msg, page)

import Algorithm
import Cube exposing (Cube)
import PLL
import PLLTrainer.States.CorrectPage
import PLLTrainer.States.EvaluateResult
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.States.TestRunning
import PLLTrainer.States.TypeOfWrongPage
import PLLTrainer.States.WrongPage
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Ports
import Process
import Random
import Shared
import StatefulPage
import Task
import Time
import TimeInterval exposing (TimeInterval)
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
      , currentTestCase = PLLTrainer.TestCase.build PLLTrainer.TestCase.NoAUF PLL.Aa PLLTrainer.TestCase.NoAUF
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

                EndTest arguments Nothing ->
                    ( { model
                        | expectedCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (PLLTrainer.TestCase.toAlg model.currentTestCase)
                      }
                    , Task.perform (TransitionMsg << EndTest arguments << Just) Time.now
                    )

                EndTest { startTime } (Just endTime) ->
                    let
                        arguments =
                            { result =
                                TimeInterval.betweenTimestamps
                                    { start = startTime
                                    , end = endTime
                                    }

                            -- We disable transitions to start in case people
                            -- are button mashing to stop the test
                            , transitionsDisabled = True
                            }

                        ( stateModel, stateCmd ) =
                            ((states shared model).evaluateResult arguments).init
                    in
                    ( { model
                        | trainerState = EvaluateResult stateModel arguments
                      }
                    , Cmd.batch
                        [ stateCmd
                        , Task.perform
                            (always <| TransitionMsg EnableEvaluateResultTransitions)
                            -- 200 ms should be enough to prevent accidental further
                            -- transitions based on some manual tests
                            (Process.sleep 200)
                        ]
                    )

                EnableEvaluateResultTransitions ->
                    case model.trainerState of
                        EvaluateResult stateModel arguments ->
                            let
                                newTrainerState =
                                    EvaluateResult stateModel { arguments | transitionsDisabled = False }
                            in
                            ( { model | trainerState = newTrainerState }, Cmd.none )

                        _ ->
                            ( model, Ports.logError "Unexpected enable evaluate result transitions outside of EvaluateResult state" )

                EvaluateCorrect ->
                    ( { model | trainerState = CorrectPage }, Cmd.none )

                EvaluateWrong ->
                    ( { model | trainerState = TypeOfWrongPage }
                    , Cmd.none
                    )

                WrongButNoMoveApplied ->
                    ( { model
                        | trainerState = WrongPage
                        , expectedCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (Algorithm.inverse <|
                                        PLLTrainer.TestCase.toAlg model.currentTestCase
                                    )
                      }
                    , Cmd.none
                    )

                WrongButExpectedStateWasReached ->
                    ( { model | trainerState = WrongPage }, Cmd.none )

                WrongAndUnrecoverable ->
                    ( { model | trainerState = WrongPage, expectedCubeState = Cube.solved }, Cmd.none )

        StateMsg typeOfLocalMsg ->
            case ( typeOfLocalMsg, model.trainerState ) of
                ( TestRunningMsg localMsg, TestRunning localModel arguments ) ->
                    ((states shared model).testRunning arguments).update localMsg localModel
                        |> Tuple.mapFirst
                            (\newTrainerState ->
                                { model | trainerState = TestRunning newTrainerState arguments }
                            )

                ( EvaluateResultMsg localMsg, EvaluateResult localModel arguments ) ->
                    ((states shared model).evaluateResult arguments).update localMsg localModel
                        |> Tuple.mapFirst
                            (\newTrainerState ->
                                { model | trainerState = EvaluateResult newTrainerState arguments }
                            )

                ( localMsg, trainerState ) ->
                    ( model
                    , let
                        localMsgString =
                            case localMsg of
                                TestRunningMsg _ ->
                                    "TestRunningMsg"

                                EvaluateResultMsg _ ->
                                    "EvaluateResultMsg"

                        trainerStateString =
                            case trainerState of
                                StartPage ->
                                    "StartPage"

                                GetReadyScreen ->
                                    "GetReadyScreen"

                                TestRunning _ { startTime } ->
                                    "TestRunning: { startTime = "
                                        ++ String.fromInt (Time.posixToMillis startTime)
                                        ++ " }"

                                EvaluateResult _ { result, transitionsDisabled } ->
                                    "EvaluateResult: { result = "
                                        ++ TimeInterval.toString result
                                        ++ ", transitionsDisabled = "
                                        ++ stringFromBool transitionsDisabled
                                        ++ " }"

                                CorrectPage ->
                                    "CorrectPage"

                                TypeOfWrongPage ->
                                    "TypeOfWrongPage"

                                WrongPage ->
                                    "WrongPage"
                      in
                      Ports.logError
                        ("Unexpected msg `"
                            ++ localMsgString
                            ++ "` during state `"
                            ++ trainerStateString
                            ++ "`"
                        )
                    )


stringFromBool : Bool -> String
stringFromBool bool =
    case bool of
        True ->
            "True"

        False ->
            "False"


type TransitionMsg
    = GetReadyForTest
    | StartTest StartTestData
    | EndTest { startTime : Time.Posix } (Maybe Time.Posix)
    | EnableEvaluateResultTransitions
    | EvaluateCorrect
    | EvaluateWrong
    | WrongButNoMoveApplied
    | WrongButExpectedStateWasReached
    | WrongAndUnrecoverable


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning PLLTrainer.States.TestRunning.Model { startTime : Time.Posix }
    | EvaluateResult PLLTrainer.States.EvaluateResult.Model { result : TimeInterval, transitionsDisabled : Bool }
    | CorrectPage
    | TypeOfWrongPage
    | WrongPage


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
    | EvaluateResultMsg PLLTrainer.States.EvaluateResult.Msg


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

                EvaluateResult stateModel arguments ->
                    ((states shared model).evaluateResult arguments).view stateModel

                CorrectPage ->
                    ((states shared model).correctPage ()).view ()

                TypeOfWrongPage ->
                    ((states shared model).typeOfWrongPage ()).view ()

                WrongPage ->
                    ((states shared model).wrongPage ()).view ()

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle stateView


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    case model.trainerState of
        StartPage ->
            ((states shared model).startPage ()).subscriptions ()

        GetReadyScreen ->
            ((states shared model).getReadyScreen ()).subscriptions ()

        TestRunning stateModel arguments ->
            ((states shared model).testRunning arguments).subscriptions stateModel

        EvaluateResult stateModel arguments ->
            ((states shared model).evaluateResult arguments).subscriptions stateModel

        CorrectPage ->
            ((states shared model).correctPage ()).subscriptions ()

        TypeOfWrongPage ->
            ((states shared model).typeOfWrongPage ()).subscriptions ()

        WrongPage ->
            ((states shared model).wrongPage ()).subscriptions ()


states :
    Shared.Model
    -> Model
    ->
        { startPage : State () () ()
        , getReadyScreen : State () () ()
        , testRunning : State PLLTrainer.States.TestRunning.Msg PLLTrainer.States.TestRunning.Model { startTime : Time.Posix }
        , evaluateResult : State PLLTrainer.States.EvaluateResult.Msg PLLTrainer.States.EvaluateResult.Model { result : TimeInterval, transitionsDisabled : Bool }
        , correctPage : State () () ()
        , typeOfWrongPage : State () () ()
        , wrongPage : State () () ()
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
            , subscriptions = always state.subscriptions
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
            , subscriptions = always Sub.none
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
                        { endTest = TransitionMsg (EndTest arguments Nothing) }
            in
            { init = ( state.init, Cmd.none )
            , view = state.view
            , subscriptions = always state.subscriptions
            , update = \msg myModel -> Tuple.pair (state.update msg myModel) Cmd.none
            }
    , evaluateResult =
        \arguments ->
            let
                fullArguments =
                    { expectedCubeState = model.expectedCubeState
                    , result = arguments.result
                    , transitionsDisabled = arguments.transitionsDisabled
                    }

                state =
                    PLLTrainer.States.EvaluateResult.state
                        shared
                        { evaluateCorrect = TransitionMsg EvaluateCorrect
                        , evaluateWrong = TransitionMsg EvaluateWrong
                        , noOp = NoOp
                        }
                        fullArguments
                        (StateMsg << EvaluateResultMsg)
            in
            { init = ( state.init, Cmd.none )
            , view = always <| state.view
            , subscriptions = state.subscriptions
            , update = \msg previousModel -> ( state.update msg previousModel, Cmd.none )
            }
    , correctPage =
        always <|
            let
                state =
                    PLLTrainer.States.CorrectPage.state
                        shared
                        { startTest = TransitionMsg GetReadyForTest
                        , noOp = NoOp
                        }
            in
            { init = ( (), Cmd.none )
            , view = always <| state.view
            , subscriptions = always state.subscriptions
            , update = \_ _ -> ( (), Cmd.none )
            }
    , typeOfWrongPage =
        \arguments ->
            let
                state =
                    PLLTrainer.States.TypeOfWrongPage.state
                        shared
                        { noMoveWasApplied = TransitionMsg WrongButNoMoveApplied
                        , expectedStateWasReached = TransitionMsg WrongButExpectedStateWasReached
                        , cubeUnrecoverable = TransitionMsg WrongAndUnrecoverable
                        , noOp = NoOp
                        }
                        { expectedCubeState = model.expectedCubeState
                        , testCase = model.currentTestCase
                        }
            in
            { init = ( (), Cmd.none )
            , view = always <| state.view
            , subscriptions = always state.subscriptions
            , update = \_ _ -> ( (), Cmd.none )
            }
    , wrongPage =
        \arguments ->
            let
                state =
                    PLLTrainer.States.WrongPage.state
                        shared
                        { startNextTest = TransitionMsg GetReadyForTest
                        , noOp = NoOp
                        }
                        { expectedCubeState = model.expectedCubeState
                        , testCase = model.currentTestCase
                        }
            in
            { init = ( (), Cmd.none )
            , view = always <| state.view
            , subscriptions = always state.subscriptions
            , update = \_ _ -> ( (), Cmd.none )
            }
    }


type alias State msg model arguments =
    arguments
    ->
        { init : ( model, Cmd Msg )
        , view : model -> StatefulPage.StateView Msg
        , subscriptions : model -> Sub Msg
        , update : msg -> model -> ( model, Cmd Msg )
        }
