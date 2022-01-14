module PLLTrainer.Page exposing (Model, Msg, page)

import AUF
import AUF.Extra
import Algorithm exposing (Algorithm)
import Cube exposing (Cube)
import Effect exposing (Effect)
import Json.Decode
import PLL exposing (PLL)
import PLLTrainer.State
import PLLTrainer.States.CorrectPage
import PLLTrainer.States.EvaluateResult
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.PickAlgorithmPage
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
import User exposing (User)
import View exposing (View)


page : Shared.Model -> Page.With Model Msg
page shared =
    Page.advanced
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
    | PickAlgorithmPage PLLTrainer.States.PickAlgorithmPage.Model PickAlgorithmExtraState
    | CorrectPage
    | TypeOfWrongPage TypeOfWrongExtraState
    | WrongPage


type alias TestRunningExtraState =
    { startTime : Time.Posix }


type alias EvaluateResultExtraState =
    { testStartTime : Time.Posix, result : TimeInterval, transitionsDisabled : Bool }


type alias TypeOfWrongExtraState =
    { testResult : User.TestResult }


type alias PickAlgorithmExtraState =
    { nextTrainerState : TrainerState
    , testResult : User.TestResult
    }


init : ( Model, Effect Msg )
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
    , Effect.none
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
      -- Meant to be sent with `Nothing` as the second Posix time, and
      -- then the end time is figured out internally
    | EndTest { startTime : Time.Posix } (Maybe Time.Posix)
    | EnableEvaluateResultTransitions
    | EvaluateCorrect { testStartTime : Time.Posix, result : TimeInterval }
    | AlgorithmPicked TrainerState User.TestResult Algorithm
    | EvaluateWrong { testStartTime : Time.Posix }
    | WrongButNoMoveApplied { testResult : User.TestResult }
    | WrongButExpectedStateWasReached { testResult : User.TestResult }
    | WrongAndUnrecoverable { testResult : User.TestResult }


type StateMsg
    = TestRunningMsg PLLTrainer.States.TestRunning.Msg
    | EvaluateResultMsg PLLTrainer.States.EvaluateResult.Msg
    | PickAlgorithmMsg PLLTrainer.States.PickAlgorithmPage.Msg


type InternalMsg
    = TESTONLYSetTestCase (Result Json.Decode.Error TestCase)
    | TESTONLYSetExtraAlgToApplyToAllCubes (Result Algorithm.FromStringError Algorithm)
    | TESTONLYSetCubeSizeOverride (Maybe Int)


{-| We use this structure to make sure the test case
is generated before the start time, so we can ensure
we don't record the start time until the very last moment
-}
type StartTestData
    = NothingGenerated
    | TestCaseGenerated TestCase
    | EverythingGenerated TestCase Time.Posix


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
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
                    , Effect.fromCmd cmd
                    )

                StartTest NothingGenerated ->
                    ( model
                    , Effect.fromCmd <|
                        Random.generate
                            (TransitionMsg << StartTest << TestCaseGenerated)
                            PLLTrainer.TestCase.generate
                    )

                StartTest (TestCaseGenerated testCase) ->
                    ( model
                    , Effect.fromCmd <|
                        Task.perform
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
                    , Effect.fromCmd stateCmd
                    )

                EndTest arguments Nothing ->
                    ( { model
                        | expectedCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (PLLTrainer.TestCase.toAlg shared.user model.currentTestCase)
                      }
                    , Effect.fromCmd <|
                        Task.perform
                            (TransitionMsg << EndTest arguments << Just)
                            Time.now
                    )

                EndTest { startTime } (Just endTime) ->
                    let
                        arguments =
                            { testStartTime = startTime
                            , result =
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
                    , Effect.fromCmd <|
                        Cmd.batch
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
                            ( { model | trainerState = newTrainerState }, Effect.none )

                        _ ->
                            ( model
                            , Effect.fromCmd <|
                                Ports.logError "Unexpected enable evaluate result transitions outside of EvaluateResult state"
                            )

                EvaluateCorrect { testStartTime, result } ->
                    let
                        testResult =
                            User.Correct
                                { timestamp = testStartTime
                                , preAUF = PLLTrainer.TestCase.preAUF model.currentTestCase
                                , postAUF = PLLTrainer.TestCase.postAUF model.currentTestCase
                                , resultInMilliseconds = TimeInterval.asMilliseconds result
                                }
                    in
                    if
                        User.hasChosenPLLAlgorithmFor
                            (PLLTrainer.TestCase.pll model.currentTestCase)
                            shared.user
                    then
                        ( { model | trainerState = CorrectPage }
                        , Effect.fromShared <|
                            Shared.ModifyUser <|
                                recordPLLTestResultWithErrorHandling
                                    (PLLTrainer.TestCase.pll model.currentTestCase)
                                    testResult
                        )

                    else
                        let
                            extraState =
                                { nextTrainerState = CorrectPage
                                , testResult = testResult
                                }

                            ( stateModel, stateCmd ) =
                                ((states shared model).pickAlgorithmPage extraState).init
                        in
                        ( { model | trainerState = PickAlgorithmPage stateModel extraState }
                        , Effect.fromCmd <| stateCmd
                        )

                EvaluateWrong arguments ->
                    let
                        testResult =
                            User.Wrong
                                { timestamp = arguments.testStartTime
                                , preAUF = PLLTrainer.TestCase.preAUF model.currentTestCase
                                , postAUF = PLLTrainer.TestCase.postAUF model.currentTestCase
                                }
                    in
                    ( { model | trainerState = TypeOfWrongPage { testResult = testResult } }
                    , if
                        User.hasChosenPLLAlgorithmFor
                            (PLLTrainer.TestCase.pll model.currentTestCase)
                            shared.user
                      then
                        Effect.fromShared <|
                            Shared.ModifyUser <|
                                recordPLLTestResultWithErrorHandling
                                    (PLLTrainer.TestCase.pll model.currentTestCase)
                                    testResult

                      else
                        Effect.none
                    )

                AlgorithmPicked nextTrainerState testResult algorithm ->
                    case
                        AUF.Extra.detectAUFs
                            { toMatchTo = PLLTrainer.TestCase.toAlg shared.user model.currentTestCase
                            , toDetectFor = algorithm
                            }
                    of
                        Err AUF.Extra.NoAUFsMakeThemMatch ->
                            ( model, Effect.fromCmd <| Ports.logError "the algorithm picked didn't match the case" )

                        Ok ( correctedPreAUF, correctedPostAUF ) ->
                            let
                                correctedTestCase =
                                    PLLTrainer.TestCase.build
                                        correctedPreAUF
                                        (PLLTrainer.TestCase.pll model.currentTestCase)
                                        correctedPostAUF

                                correctedTestResult =
                                    case testResult of
                                        User.Correct arguments ->
                                            User.Correct { arguments | preAUF = correctedPreAUF, postAUF = correctedPostAUF }

                                        User.Wrong arguments ->
                                            User.Wrong { arguments | preAUF = correctedPreAUF, postAUF = correctedPostAUF }
                            in
                            ( { model | currentTestCase = correctedTestCase, trainerState = nextTrainerState }
                            , Effect.fromShared <|
                                Shared.ModifyUser
                                    (User.changePLLAlgorithm
                                        (PLLTrainer.TestCase.pll correctedTestCase)
                                        algorithm
                                        >> recordPLLTestResultWithErrorHandling
                                            (PLLTrainer.TestCase.pll correctedTestCase)
                                            correctedTestResult
                                    )
                            )

                WrongButNoMoveApplied { testResult } ->
                    let
                        newCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (Algorithm.inverse <|
                                        PLLTrainer.TestCase.toAlg shared.user model.currentTestCase
                                    )
                    in
                    if
                        User.hasChosenPLLAlgorithmFor
                            (PLLTrainer.TestCase.pll model.currentTestCase)
                            shared.user
                    then
                        ( { model | trainerState = WrongPage, expectedCubeState = newCubeState }, Effect.none )

                    else
                        let
                            extraState =
                                { nextTrainerState = WrongPage
                                , testResult = testResult
                                }

                            ( stateModel, stateCmd ) =
                                ((states shared model).pickAlgorithmPage extraState).init
                        in
                        ( { model
                            | trainerState = PickAlgorithmPage stateModel extraState
                            , expectedCubeState = newCubeState
                          }
                        , Effect.fromCmd stateCmd
                        )

                WrongButExpectedStateWasReached { testResult } ->
                    if
                        User.hasChosenPLLAlgorithmFor
                            (PLLTrainer.TestCase.pll model.currentTestCase)
                            shared.user
                    then
                        ( { model | trainerState = WrongPage }, Effect.none )

                    else
                        let
                            extraState =
                                { nextTrainerState = WrongPage
                                , testResult = testResult
                                }

                            ( stateModel, stateCmd ) =
                                ((states shared model).pickAlgorithmPage extraState).init
                        in
                        ( { model
                            | trainerState = PickAlgorithmPage stateModel extraState
                          }
                        , Effect.fromCmd stateCmd
                        )

                WrongAndUnrecoverable { testResult } ->
                    if
                        User.hasChosenPLLAlgorithmFor
                            (PLLTrainer.TestCase.pll model.currentTestCase)
                            shared.user
                    then
                        ( { model | trainerState = WrongPage, expectedCubeState = Cube.solved }, Effect.none )

                    else
                        let
                            extraState =
                                { nextTrainerState = WrongPage
                                , testResult = testResult
                                }

                            ( stateModel, stateCmd ) =
                                ((states shared model).pickAlgorithmPage extraState).init
                        in
                        ( { model
                            | trainerState = PickAlgorithmPage stateModel extraState
                            , expectedCubeState = Cube.solved
                          }
                        , Effect.fromCmd stateCmd
                        )

        StateMsg stateMsg ->
            Tuple.mapSecond Effect.fromCmd <|
                handleStateMsgBoilerplate shared model stateMsg

        InternalMsg internalMsg ->
            case internalMsg of
                TESTONLYSetTestCase (Ok testCase) ->
                    ( { model | currentTestCase = testCase }, Effect.none )

                TESTONLYSetTestCase (Err decodeError) ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.logError
                            ("Error in test only set test case: "
                                ++ Json.Decode.errorToString decodeError
                            )
                    )

                TESTONLYSetExtraAlgToApplyToAllCubes (Ok algorithm) ->
                    ( model, Effect.fromShared (Shared.TESTONLYSetExtraAlgToApplyToAllCubes algorithm) )

                TESTONLYSetExtraAlgToApplyToAllCubes (Err error) ->
                    case error of
                        Algorithm.EmptyAlgorithm ->
                            ( model
                            , Effect.fromShared
                                (Shared.TESTONLYSetExtraAlgToApplyToAllCubes Algorithm.empty)
                            )

                        _ ->
                            ( model
                            , Effect.fromCmd <|
                                Ports.logError
                                    ("Error in test only set extra alg to apply to all cubes: "
                                        ++ Algorithm.debugFromStringError error
                                    )
                            )

                TESTONLYSetCubeSizeOverride size ->
                    ( model, Effect.fromShared (Shared.TESTONLYSetCubeSizeOverride size) )

        NoOp ->
            ( model, Effect.none )


recordPLLTestResultWithErrorHandling : PLL -> User.TestResult -> User -> ( User, Maybe { errorMessage : String } )
recordPLLTestResultWithErrorHandling pll testResult user =
    case
        User.recordPLLTestResult
            pll
            testResult
            user
    of
        Ok newUser ->
            ( newUser, Nothing )

        Err error ->
            case error of
                User.NoAlgorithmPickedYet ->
                    ( user
                    , Just
                        { errorMessage =
                            "You can't record a result before an algorithm has been picked"
                        }
                    )



-- SUBSCRIPTIONS


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    Sub.batch
        [ handleStateSubscriptionsBoilerplate shared model
            |> PLLTrainer.Subscription.getSub
        , Ports.onTESTONLYSetTestCase (InternalMsg << TESTONLYSetTestCase)
        , Ports.onTESTONLYSetExtraAlgToApplyToAllCubes (InternalMsg << TESTONLYSetExtraAlgToApplyToAllCubes)
        , Ports.onTESTONLYSetCubeSizeOverride (InternalMsg << TESTONLYSetCubeSizeOverride)
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
        , pickAlgorithmPage :
            StateBuilder
                PLLTrainer.States.PickAlgorithmPage.Msg
                PLLTrainer.States.PickAlgorithmPage.Model
                PickAlgorithmExtraState
        , correctPage : StateBuilder () () ()
        , typeOfWrongPage : StateBuilder () () TypeOfWrongExtraState
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
                { evaluateCorrect =
                    TransitionMsg
                        (EvaluateCorrect
                            { testStartTime = arguments.testStartTime, result = arguments.result }
                        )
                , evaluateWrong = TransitionMsg (EvaluateWrong { testStartTime = arguments.testStartTime })
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , result = arguments.result
                , transitionsDisabled = arguments.transitionsDisabled
                }
                (StateMsg << EvaluateResultMsg)
    , pickAlgorithmPage =
        \{ nextTrainerState, testResult } ->
            PLLTrainer.States.PickAlgorithmPage.state
                { currentTestCase = model.currentTestCase
                , testCaseResult = testResult
                }
                shared
                { continue = TransitionMsg << AlgorithmPicked nextTrainerState testResult
                , noOp = NoOp
                }
                (StateMsg << PickAlgorithmMsg)
    , correctPage =
        always <|
            PLLTrainer.States.CorrectPage.state
                shared
                { startTest = TransitionMsg GetReadyForTest
                , noOp = NoOp
                }
    , typeOfWrongPage =
        \arguments ->
            PLLTrainer.States.TypeOfWrongPage.state
                shared
                { noMoveWasApplied = TransitionMsg (WrongButNoMoveApplied { testResult = arguments.testResult })
                , expectedStateWasReached = TransitionMsg (WrongButExpectedStateWasReached { testResult = arguments.testResult })
                , cubeUnrecoverable = TransitionMsg (WrongAndUnrecoverable { testResult = arguments.testResult })
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
                    (\newStateModel ->
                        { model | trainerState = TestRunning newStateModel arguments }
                    )

        ( EvaluateResultMsg localMsg, EvaluateResult localModel arguments ) ->
            ((states shared model).evaluateResult arguments).update localMsg localModel
                |> Tuple.mapFirst
                    (\newStateModel ->
                        { model | trainerState = EvaluateResult newStateModel arguments }
                    )

        ( PickAlgorithmMsg localMsg, PickAlgorithmPage localModel extraState ) ->
            ((states shared model).pickAlgorithmPage extraState).update localMsg localModel
                |> Tuple.mapFirst
                    (\newStateModel ->
                        { model | trainerState = PickAlgorithmPage newStateModel extraState }
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

        PickAlgorithmMsg _ ->
            "PickAlgorithmMsg"


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

        PickAlgorithmPage _ _ ->
            "PickAlgorithmPage"

        CorrectPage ->
            "CorrectPage"

        TypeOfWrongPage _ ->
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

        PickAlgorithmPage stateModel arguments ->
            ((states shared model).pickAlgorithmPage arguments).subscriptions stateModel

        CorrectPage ->
            ((states shared model).correctPage ()).subscriptions ()

        TypeOfWrongPage arguments ->
            ((states shared model).typeOfWrongPage arguments).subscriptions ()

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

        PickAlgorithmPage stateModel arguments ->
            ((states shared model).pickAlgorithmPage arguments).view stateModel

        CorrectPage ->
            ((states shared model).correctPage ()).view ()

        TypeOfWrongPage arguments ->
            ((states shared model).typeOfWrongPage arguments).view ()

        WrongPage ->
            ((states shared model).wrongPage ()).view ()
