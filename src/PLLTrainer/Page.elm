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
import PLLTrainer.States.PickAlgorithmPage
import PLLTrainer.States.PickTargetParametersPage
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
        { init = init shared
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
    = PickTargetParametersPage PLLTrainer.States.PickTargetParametersPage.Model
    | StartPage
    | TestRunning (PLLTrainer.States.TestRunning.Model Msg) TestRunningExtraState
    | EvaluateResult PLLTrainer.States.EvaluateResult.Model EvaluateResultExtraState
    | PickAlgorithmPage PLLTrainer.States.PickAlgorithmPage.Model PickAlgorithmExtraState
    | CorrectPage
    | TypeOfWrongPage TypeOfWrongExtraState
    | WrongPage


type TestRunningExtraState
    = GettingReadyExtraState
    | TestRunningExtraState { testTimestamp : Time.Posix, memoizedCube : Cube }


type alias EvaluateResultExtraState =
    { testTimestamp : Time.Posix, result : TimeInterval, transitionsDisabled : Bool }


type alias TypeOfWrongExtraState =
    { testResult : User.TestResult }


type alias PickAlgorithmExtraState =
    { nextTrainerState : TrainerState
    , testResult : User.TestResult
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { trainerState =
            if User.hasChosenPLLTargetParameters shared.user then
                StartPage

            else
                PickTargetParametersPage
                    (Tuple.first ((states shared).pickTargetParametersPage ()).init)
      , expectedCubeState = Cube.solved

      -- This is just a placeholder as new test cases are always generated
      -- just before the test is run, and this way we avoid a more complex
      -- type that for example needs to represent that there's no test case
      -- until after the first test has begun which would then
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
    | EndTest { testTimestamp : Time.Posix } TimeInterval
    | EnableEvaluateResultTransitions
    | EvaluateCorrect { testTimestamp : Time.Posix, result : TimeInterval }
    | AlgorithmPicked TrainerState User.TestResult Algorithm
    | EvaluateWrong { testTimestamp : Time.Posix }
    | WrongButNoMoveApplied { testResult : User.TestResult }
    | WrongButExpectedStateWasReached { testResult : User.TestResult }
    | WrongAndUnrecoverable { testResult : User.TestResult }


type StateMsg
    = PickTargetParametersMsg PLLTrainer.States.PickTargetParametersPage.Msg
    | TestRunningMsg PLLTrainer.States.TestRunning.Msg
    | EvaluateResultMsg PLLTrainer.States.EvaluateResult.Msg
    | PickAlgorithmMsg PLLTrainer.States.PickAlgorithmPage.Msg


type InternalMsg
    = TESTONLYSetTestCase (Result Json.Decode.Error TestCase)
    | TESTONLYSetExtraAlgToApplyToAllCubes (Result Algorithm.FromStringError Algorithm)
    | TESTONLYSetCubeSizeOverride (Maybe Int)


{-| We use this structure to make sure there is a set
order of generation of the different outside effects
-}
type StartTestData
    = NothingGenerated
    | TimestampGenerated Time.Posix
    | EverythingGenerated Time.Posix TestCase


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        TransitionMsg transition ->
            case transition of
                GetReadyForTest ->
                    let
                        ( stateModel, stateCmd ) =
                            ((states shared).testRunning GettingReadyExtraState).init
                    in
                    ( { model | trainerState = TestRunning stateModel GettingReadyExtraState }
                    , Effect.fromCmd stateCmd
                    )

                StartTest NothingGenerated ->
                    ( model
                    , Effect.fromCmd <|
                        Task.perform
                            (TransitionMsg << StartTest << TimestampGenerated)
                            Time.now
                    )

                StartTest (TimestampGenerated testTimestamp) ->
                    ( model
                    , Effect.fromCmd <|
                        Random.generate
                            (TransitionMsg << StartTest << EverythingGenerated testTimestamp)
                            (PLLTrainer.TestCase.generate testTimestamp shared.user)
                    )

                StartTest (EverythingGenerated testTimestamp testCase) ->
                    let
                        extraState =
                            TestRunningExtraState
                                { testTimestamp = testTimestamp
                                , memoizedCube = PLLTrainer.TestCase.toCube shared.user testCase
                                }

                        ( stateModel, stateCmd ) =
                            ((states shared).testRunning extraState).init
                    in
                    ( { model
                        | trainerState = TestRunning stateModel extraState
                        , currentTestCase = testCase
                      }
                    , Effect.fromCmd stateCmd
                    )

                EndTest { testTimestamp } result ->
                    let
                        extraState =
                            { testTimestamp = testTimestamp
                            , result = result

                            -- We disable transitions to start in case people
                            -- are button mashing to stop the test
                            , transitionsDisabled = True
                            }

                        ( stateModel, stateCmd ) =
                            ((states shared).evaluateResult model extraState).init
                    in
                    ( { model
                        | trainerState = EvaluateResult stateModel extraState
                        , expectedCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (PLLTrainer.TestCase.toAlg shared.user model.currentTestCase)
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
                        EvaluateResult stateModel extraState ->
                            let
                                newTrainerState =
                                    EvaluateResult stateModel { extraState | transitionsDisabled = False }
                            in
                            ( { model | trainerState = newTrainerState }, Effect.none )

                        _ ->
                            ( model
                            , Effect.fromCmd <|
                                Ports.logError "Unexpected enable evaluate result transitions outside of EvaluateResult state"
                            )

                EvaluateCorrect { testTimestamp, result } ->
                    let
                        testResult =
                            User.Correct
                                { timestamp = testTimestamp
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
                                ((states shared).pickAlgorithmPage model extraState).init
                        in
                        ( { model | trainerState = PickAlgorithmPage stateModel extraState }
                        , Effect.fromCmd <| stateCmd
                        )

                EvaluateWrong extraState ->
                    let
                        testResult =
                            User.Wrong
                                { timestamp = extraState.testTimestamp
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
                                        User.Correct parameters ->
                                            User.Correct { parameters | preAUF = correctedPreAUF, postAUF = correctedPostAUF }

                                        User.Wrong parameters ->
                                            User.Wrong { parameters | preAUF = correctedPreAUF, postAUF = correctedPostAUF }
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
                                ((states shared).pickAlgorithmPage model extraState).init
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
                                ((states shared).pickAlgorithmPage model extraState).init
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
                                ((states shared).pickAlgorithmPage model extraState).init
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
                    let
                        withUpdatedTestCase =
                            { model | currentTestCase = testCase }

                        fullyUpdatedModel =
                            case model.trainerState of
                                TestRunning localModel (TestRunningExtraState extraState) ->
                                    let
                                        newExtraState =
                                            { extraState | memoizedCube = PLLTrainer.TestCase.toCube shared.user testCase }

                                        newLocalModel =
                                            ((states shared).testRunning (TestRunningExtraState newExtraState)).update
                                                (PLLTrainer.States.TestRunning.tESTONLYUpdateMemoizedCube newExtraState.memoizedCube)
                                                localModel
                                                |> Tuple.first
                                    in
                                    { withUpdatedTestCase | trainerState = TestRunning newLocalModel (TestRunningExtraState newExtraState) }

                                _ ->
                                    withUpdatedTestCase
                    in
                    ( fullyUpdatedModel, Effect.none )

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


type alias StateBuilder localMsg model extraState =
    extraState
    -> PLLTrainer.State.State Msg localMsg model


states :
    Shared.Model
    ->
        { pickTargetParametersPage :
            StateBuilder
                PLLTrainer.States.PickTargetParametersPage.Msg
                PLLTrainer.States.PickTargetParametersPage.Model
                ()
        , startPage : StateBuilder () () ()
        , testRunning :
            StateBuilder
                PLLTrainer.States.TestRunning.Msg
                (PLLTrainer.States.TestRunning.Model Msg)
                TestRunningExtraState
        , evaluateResult :
            Model
            ->
                StateBuilder
                    PLLTrainer.States.EvaluateResult.Msg
                    PLLTrainer.States.EvaluateResult.Model
                    EvaluateResultExtraState
        , pickAlgorithmPage :
            Model
            ->
                StateBuilder
                    PLLTrainer.States.PickAlgorithmPage.Msg
                    PLLTrainer.States.PickAlgorithmPage.Model
                    PickAlgorithmExtraState
        , correctPage : StateBuilder () () ()
        , typeOfWrongPage : Model -> StateBuilder () () TypeOfWrongExtraState
        , wrongPage : Model -> StateBuilder () () ()
        }
states shared =
    { pickTargetParametersPage =
        always <|
            PLLTrainer.States.PickTargetParametersPage.state
                shared
                { submit = NoOp
                }
                (StateMsg << PickTargetParametersMsg)
    , startPage =
        always <|
            PLLTrainer.States.StartPage.state
                shared
                { startTest = TransitionMsg GetReadyForTest
                , noOp = NoOp
                }
    , testRunning =
        \extraState ->
            let
                argument =
                    case extraState of
                        GettingReadyExtraState ->
                            PLLTrainer.States.TestRunning.GetReadyArgument
                                { startTest = TransitionMsg <| StartTest NothingGenerated }

                        TestRunningExtraState { memoizedCube, testTimestamp } ->
                            PLLTrainer.States.TestRunning.TestRunningArgument
                                { memoizedCube = memoizedCube
                                , endTest = TransitionMsg << EndTest { testTimestamp = testTimestamp }
                                }
            in
            PLLTrainer.States.TestRunning.state
                shared
                argument
                (StateMsg << TestRunningMsg)
    , evaluateResult =
        \model extraState ->
            PLLTrainer.States.EvaluateResult.state
                shared
                { evaluateCorrect =
                    TransitionMsg
                        (EvaluateCorrect
                            { testTimestamp = extraState.testTimestamp, result = extraState.result }
                        )
                , evaluateWrong = TransitionMsg (EvaluateWrong { testTimestamp = extraState.testTimestamp })
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , result = extraState.result
                , transitionsDisabled = extraState.transitionsDisabled
                }
                (StateMsg << EvaluateResultMsg)
    , pickAlgorithmPage =
        \model { nextTrainerState, testResult } ->
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
        \model extraState ->
            PLLTrainer.States.TypeOfWrongPage.state
                shared
                { noMoveWasApplied = TransitionMsg (WrongButNoMoveApplied { testResult = extraState.testResult })
                , expectedStateWasReached = TransitionMsg (WrongButExpectedStateWasReached { testResult = extraState.testResult })
                , cubeUnrecoverable = TransitionMsg (WrongAndUnrecoverable { testResult = extraState.testResult })
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , testCase = model.currentTestCase
                }
    , wrongPage =
        \model _ ->
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
        ( TestRunningMsg localMsg, TestRunning localModel extraState ) ->
            ((states shared).testRunning extraState).update localMsg localModel
                |> Tuple.mapFirst
                    (\newStateModel ->
                        { model | trainerState = TestRunning newStateModel extraState }
                    )

        ( EvaluateResultMsg localMsg, EvaluateResult localModel extraState ) ->
            ((states shared).evaluateResult model extraState).update localMsg localModel
                |> Tuple.mapFirst
                    (\newStateModel ->
                        { model | trainerState = EvaluateResult newStateModel extraState }
                    )

        ( PickAlgorithmMsg localMsg, PickAlgorithmPage localModel extraState ) ->
            ((states shared).pickAlgorithmPage model extraState).update localMsg localModel
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
        PickTargetParametersMsg _ ->
            "PickTargetParametersMsg"

        TestRunningMsg _ ->
            "TestRunningMsg"

        EvaluateResultMsg _ ->
            "EvaluateResultMsg"

        PickAlgorithmMsg _ ->
            "PickAlgorithmMsg"


trainerStateToString : TrainerState -> String
trainerStateToString trainerState =
    case trainerState of
        PickTargetParametersPage _ ->
            "PickTargetParametersPage"

        StartPage ->
            "StartPage"

        TestRunning _ extraState ->
            "TestRunning: "
                ++ (case extraState of
                        GettingReadyExtraState ->
                            "GettingReadyExtraState"

                        TestRunningExtraState { testTimestamp } ->
                            "TestRunningExtraState: { testTimestamp = "
                                ++ String.fromInt (Time.posixToMillis testTimestamp)
                                ++ " }"
                   )

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
        PickTargetParametersPage stateModel ->
            ((states shared).pickTargetParametersPage ()).subscriptions stateModel

        StartPage ->
            ((states shared).startPage ()).subscriptions ()

        TestRunning stateModel extraState ->
            ((states shared).testRunning extraState).subscriptions stateModel

        EvaluateResult stateModel extraState ->
            ((states shared).evaluateResult model extraState).subscriptions stateModel

        PickAlgorithmPage stateModel extraState ->
            ((states shared).pickAlgorithmPage model extraState).subscriptions stateModel

        CorrectPage ->
            ((states shared).correctPage ()).subscriptions ()

        TypeOfWrongPage extraState ->
            ((states shared).typeOfWrongPage model extraState).subscriptions ()

        WrongPage ->
            ((states shared).wrongPage model ()).subscriptions ()


handleStateViewBoilerplate : Shared.Model -> Model -> PLLTrainer.State.View Msg
handleStateViewBoilerplate shared model =
    case model.trainerState of
        PickTargetParametersPage stateModel ->
            ((states shared).pickTargetParametersPage ()).view stateModel

        StartPage ->
            ((states shared).startPage ()).view ()

        TestRunning stateModel extraState ->
            ((states shared).testRunning extraState).view stateModel

        EvaluateResult stateModel extraState ->
            ((states shared).evaluateResult model extraState).view stateModel

        PickAlgorithmPage stateModel extraState ->
            ((states shared).pickAlgorithmPage model extraState).view stateModel

        CorrectPage ->
            ((states shared).correctPage ()).view ()

        TypeOfWrongPage extraState ->
            ((states shared).typeOfWrongPage model extraState).view ()

        WrongPage ->
            ((states shared).wrongPage model ()).view ()
