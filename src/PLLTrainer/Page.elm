module PLLTrainer.Page exposing (Model, Msg, page)

import AUF
import Algorithm
import Cube exposing (Cube)
import Json.Decode
import PLL
import PLLTrainer.State
import PLLTrainer.States.CorrectPage
import PLLTrainer.States.EvaluateResult
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.States.TestRunning
import PLLTrainer.States.TypeOfWrongPage
import PLLTrainer.States.WrongPage
import PLLTrainer.Subscription
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Ports
import Process
import Random
import Shared
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



-- INIT


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning PLLTrainer.States.TestRunning.Model TestRunningExtraState
    | EvaluateResult PLLTrainer.States.EvaluateResult.Model EvaluateResultExtraState
    | CorrectPage
    | TypeOfWrongPage
    | WrongPage


type alias TestRunningExtraState =
    { startTime : Time.Posix }


type alias EvaluateResultExtraState =
    { result : TimeInterval, transitionsDisabled : Bool }


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
      , currentTestCase = PLLTrainer.TestCase.build AUF.None PLL.Aa AUF.None
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TransitionMsg TransitionMsg
    | StateMsg StateMsg
    | InternalMsg InternalMsg
    | NoOp


type TransitionMsg
    = GetReadyForTest
    | StartTest StartTestData
      -- Meant to be sent with `Nothing` as the Posix time, and
      -- then the time is figured out internally
    | EndTest { startTime : Time.Posix } (Maybe Time.Posix)
    | EnableEvaluateResultTransitions
    | EvaluateCorrect
    | EvaluateWrong
    | WrongButNoMoveApplied
    | WrongButExpectedStateWasReached
    | WrongAndUnrecoverable


type StateMsg
    = TestRunningMsg PLLTrainer.States.TestRunning.Msg
    | EvaluateResultMsg PLLTrainer.States.EvaluateResult.Msg


type InternalMsg
    = TESTONLYSetTestCase (Result Json.Decode.Error TestCase)


{-| We use this structure to make sure the test case
is generated before the start time, so we can ensure
we don't record the start time until the very last moment
-}
type StartTestData
    = NothingGenerated
    | TestCaseGenerated TestCase
    | EverythingGenerated TestCase Time.Posix


update : Shared.Model -> Msg -> Model -> ( Model, Cmd Msg )
update shared msg model =
    case msg of
        TransitionMsg transition ->
            case transition of
                GetReadyForTest ->
                    let
                        ( _, stateCmd ) =
                            ((states shared model).getReadyScreen ()).init

                        startTestAfterASecond =
                            Task.perform
                                (always <| TransitionMsg (StartTest NothingGenerated))
                                (Process.sleep 1000)

                        cmd =
                            Cmd.batch [ stateCmd, startTestAfterASecond ]
                    in
                    ( { model | trainerState = GetReadyScreen }
                    , cmd
                    )

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
                            -- Based on some manual testing, 200 ms is enough to
                            -- prevent accidental further transitions
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

        StateMsg stateMsg ->
            handleStateMsgBoilerplate shared model stateMsg

        InternalMsg internalMsg ->
            case internalMsg of
                TESTONLYSetTestCase (Ok testCase) ->
                    ( { model | currentTestCase = testCase }, Cmd.none )

                TESTONLYSetTestCase (Result.Err decodeError) ->
                    ( model
                    , Ports.logError
                        ("Error in test only set test case: "
                            ++ Json.Decode.errorToString decodeError
                        )
                    )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    Sub.batch
        [ handleStateSubscriptionsBoilerplate shared model
            |> PLLTrainer.Subscription.getSub
        , Ports.onTESTONLYSetTestCase (InternalMsg << TESTONLYSetTestCase)
        ]



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        stateView =
            handleStateViewBoilerplate shared model

        subscription =
            handleStateSubscriptionsBoilerplate shared model

        pageSubtitle =
            Nothing
    in
    PLLTrainer.State.stateViewToGlobalView pageSubtitle subscription stateView



-- BOILERPLATE


type alias StateBuilder localMsg model arguments =
    arguments
    -> PLLTrainer.State.State Msg localMsg model


states :
    Shared.Model
    -> Model
    ->
        { startPage : StateBuilder () () ()
        , getReadyScreen : StateBuilder () () ()
        , testRunning :
            StateBuilder
                PLLTrainer.States.TestRunning.Msg
                PLLTrainer.States.TestRunning.Model
                TestRunningExtraState
        , evaluateResult :
            StateBuilder
                PLLTrainer.States.EvaluateResult.Msg
                PLLTrainer.States.EvaluateResult.Model
                EvaluateResultExtraState
        , correctPage : StateBuilder () () ()
        , typeOfWrongPage : StateBuilder () () ()
        , wrongPage : StateBuilder () () ()
        }
states shared model =
    { startPage =
        always <|
            PLLTrainer.States.StartPage.state
                shared
                { startTest = TransitionMsg GetReadyForTest
                , noOp = NoOp
                }
    , getReadyScreen =
        always <|
            PLLTrainer.States.GetReadyScreen.state shared
    , testRunning =
        \arguments ->
            PLLTrainer.States.TestRunning.state
                shared
                model.currentTestCase
                (StateMsg << TestRunningMsg)
                { endTest = TransitionMsg (EndTest arguments Nothing) }
    , evaluateResult =
        \arguments ->
            PLLTrainer.States.EvaluateResult.state
                shared
                { evaluateCorrect = TransitionMsg EvaluateCorrect
                , evaluateWrong = TransitionMsg EvaluateWrong
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , result = arguments.result
                , transitionsDisabled = arguments.transitionsDisabled
                }
                (StateMsg << EvaluateResultMsg)
    , correctPage =
        always <|
            PLLTrainer.States.CorrectPage.state
                shared
                { startTest = TransitionMsg GetReadyForTest
                , noOp = NoOp
                }
    , typeOfWrongPage =
        \_ ->
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
    , wrongPage =
        \_ ->
            PLLTrainer.States.WrongPage.state
                shared
                { startNextTest = TransitionMsg GetReadyForTest
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , testCase = model.currentTestCase
                }
    }


handleStateMsgBoilerplate :
    Shared.Model
    -> Model
    -> StateMsg
    -> ( Model, Cmd Msg )
handleStateMsgBoilerplate shared model stateMsg =
    case ( stateMsg, model.trainerState ) of
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

        ( unexpectedStateMsg, unexpectedTrainerState ) ->
            ( model
            , Ports.logError
                ("Unexpected msg `"
                    ++ stateMsgToString unexpectedStateMsg
                    ++ "` during state `"
                    ++ trainerStateToString unexpectedTrainerState
                    ++ "`"
                )
            )


stateMsgToString : StateMsg -> String
stateMsgToString stateMsg =
    case stateMsg of
        TestRunningMsg _ ->
            "TestRunningMsg"

        EvaluateResultMsg _ ->
            "EvaluateResultMsg"


trainerStateToString : TrainerState -> String
trainerStateToString trainerState =
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


stringFromBool : Bool -> String
stringFromBool bool =
    if bool then
        "True"

    else
        "False"


handleStateSubscriptionsBoilerplate : Shared.Model -> Model -> PLLTrainer.Subscription.Subscription Msg
handleStateSubscriptionsBoilerplate shared model =
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


handleStateViewBoilerplate : Shared.Model -> Model -> PLLTrainer.State.View Msg
handleStateViewBoilerplate shared model =
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
