module PLLTrainer.Page exposing (Model, Msg, TrainerState, page)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Algorithm.Extra
import Browser.Dom
import Css
import Cube exposing (Cube)
import Effect exposing (Effect)
import Element
import Html.Attributes
import Json.Decode
import List.Nonempty
import Notification
import PLL exposing (PLL)
import PLL.Extra
import PLLTrainer.State
import PLLTrainer.States.AlgorithmDrillerExplanationPage
import PLLTrainer.States.AlgorithmDrillerStatusPage
import PLLTrainer.States.AlgorithmDrillerSuccessPage
import PLLTrainer.States.CorrectPage
import PLLTrainer.States.EvaluateResult
import PLLTrainer.States.NewCasePage
import PLLTrainer.States.PickAUFPreferencesPage
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
        , update =
            \msg model ->
                update shared msg model
                    |> resetScrollIfPageChanged model
        , view = view shared
        , subscriptions = subscriptions shared
        }


resetScrollIfPageChanged : Model -> ( Model, Effect Msg ) -> ( Model, Effect Msg )
resetScrollIfPageChanged model ( newModel, effect ) =
    if uniquePageIdentifier model == uniquePageIdentifier newModel then
        ( newModel, effect )

    else
        ( newModel
        , Effect.batch
            [ effect
            , Effect.fromCmd <|
                Task.perform (\_ -> NoOp) (Browser.Dom.setViewport 0 0)
            , Effect.fromCmd <|
                -- We don't care if this errors as we don't require the pages to be full screen
                Task.attempt (\_ -> NoOp) (Browser.Dom.setViewportOf View.fullScreenScrollableContainerId 0 0)
            ]
        )



-- INIT


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : { isNew : Bool, testCase : TestCase }
    , maybeDrillerState :
        Maybe
            { correctAttemptsLeft : Int
            , previousTestResult : PLLTrainer.States.AlgorithmDrillerStatusPage.PreviousTestResult
            }
    , tESTONLY :
        { nextTestCaseOverride : Maybe TestCase
        }
    }


correctAttemptsRequiredForDriller : Int
correctAttemptsRequiredForDriller =
    3


type TrainerState
    = PickTargetParametersPage PLLTrainer.States.PickTargetParametersPage.Model
    | StartPage
    | NewCasePage NewCaseExtraState
    | TestRunning (PLLTrainer.States.TestRunning.Model Msg) TestRunningExtraState
    | EvaluateResult PLLTrainer.States.EvaluateResult.Model EvaluateResultExtraState
    | PickAlgorithmPage PLLTrainer.States.PickAlgorithmPage.Model PickAlgorithmExtraState
    | PickAUFPreferencesPage PickAUFPreferencesExtraState
    | AlgorithmDrillerExplanationPage AlgorithmDrillerExplanationExtraState
    | AlgorithmDrillerStatusPage
    | AlgorithmDrillerSuccessPage
    | CorrectPage
    | TypeOfWrongPage TypeOfWrongExtraState
    | WrongPage


type alias NewCaseExtraState =
    { generator : PLLTrainer.TestCase.Generator }


type TestRunningExtraState
    = GettingReadyExtraState PLLTrainer.TestCase.Generator
    | TestRunningExtraState { testTimestamp : Time.Posix, memoizedCube : Cube }


type alias EvaluateResultExtraState =
    { testTimestamp : Time.Posix, result : TimeInterval, transitionsDisabled : Bool }


type alias TypeOfWrongExtraState =
    { nextTrainerState : ( TrainerState, Effect Msg ) }


type alias PickAlgorithmExtraState =
    { getNextTrainerState : Algorithm -> ( TrainerState, Effect Msg )
    , testResult : User.TestResult
    }


type alias PickAUFPreferencesExtraState =
    { nextTrainerState : ( TrainerState, Effect Msg )
    }


type alias AlgorithmDrillerExplanationExtraState =
    { testResult : User.TestResult
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
      , maybeDrillerState = Nothing

      -- This is just a placeholder as new test cases are always generated
      -- just before the test is run, and this way we avoid a more complex
      -- type that for example needs to represent that there's no test case
      -- until after the first test has begun which would then
      -- possibly need a Maybe or a difficult tagged type. A placeholder
      -- seems the best option of these right now
      , currentTestCase = { isNew = True, testCase = placeholderTestCase }
      , tESTONLY =
            { nextTestCaseOverride = Nothing
            }
      }
    , Effect.none
    )


{-| We extracted this into a constant for performance reasons.
The init function is called on every render and we need it to be
performant but the TestCase.build function does some heavy computations
in order to determine to optimal AUF that slows down the app
-}
placeholderTestCase : TestCase
placeholderTestCase =
    PLLTrainer.TestCase.escapeHatch ( AUF.None, PLL.Aa, AUF.None )



-- UPDATE


type Msg
    = TransitionMsg TransitionMsg
    | StateMsg StateMsg
    | InternalMsg InternalMsg
    | SubmitError String
    | NoOp


type TransitionMsg
    = SubmitNewTargetParameters { newTargetRecognitionTime : Float, newTargetTps : Float }
    | GoToEditTargetParameters
      -- Pass in Nothing when sending it and the time is generated internally
    | InitiateTest (Maybe Time.Posix)
    | NewCaseGetReadyForTest PLLTrainer.TestCase.Generator
    | StartTest StartTestData
    | EndTest { testTimestamp : Time.Posix } TimeInterval
    | EnableEvaluateResultTransitions
    | EvaluateCorrect { testTimestamp : Time.Posix, result : TimeInterval }
    | AlgorithmPicked (Algorithm -> ( TrainerState, Effect Msg )) User.TestResult Algorithm
    | AUFPreferencesPicked ( TrainerState, Effect Msg )
    | StartAlgorithmDrills
      -- Pass in Nothing when sending it and the time is generated internally
    | InitiateAlgorithmDrillerTest (Maybe Time.Posix)
    | EvaluateWrong { testTimestamp : Time.Posix }
    | WrongButNoMoveApplied { nextTrainerState : ( TrainerState, Effect Msg ) }
    | WrongButExpectedStateWasReached { nextTrainerState : ( TrainerState, Effect Msg ) }
    | WrongAndUnrecoverable { nextTrainerState : ( TrainerState, Effect Msg ) }


type StateMsg
    = PickTargetParametersMsg PLLTrainer.States.PickTargetParametersPage.Msg
    | TestRunningMsg PLLTrainer.States.TestRunning.Msg
    | EvaluateResultMsg PLLTrainer.States.EvaluateResult.Msg
    | PickAlgorithmMsg PLLTrainer.States.PickAlgorithmPage.Msg


type InternalMsg
    = TESTONLYSetTestCase (Result Json.Decode.Error ( AUF, PLL, AUF ))
    | TESTONLYOverrideNextTestCase (Result Json.Decode.Error ( AUF, PLL, AUF ))
    | TESTONLYOverrideCubeDisplayAngle (Maybe Cube.DisplayAngle)
    | TESTONLYSetCubeSizeOverride (Maybe Int)
    | TESTONLYOverrideDisplayCubeAnnotations (Maybe Bool)
    | TESTONLYSetPLLAlgorithm ( Result String PLL, Result Algorithm.FromStringError Algorithm )
    | TESTONLYSetMultiplePLLAlgorithms (Result Ports.MultiplePLLAlgorithmsError (List ( PLL, Algorithm )))
    | TESTONLYCurrentTestCaseRequested


{-| We use this structure to make sure there is a set
order of generation of the different outside effects
-}
type StartTestData
    = NothingGenerated PLLTrainer.TestCase.Generator
    | TimestampGenerated PLLTrainer.TestCase.Generator Time.Posix
    | EverythingGenerated Time.Posix { isNew : Bool, testCase : TestCase }


update : Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update shared msg model =
    case msg of
        SubmitError errorMessage ->
            ( model
            , Effect.batch
                [ Effect.fromCmd <| Ports.logError errorMessage
                , Effect.fromShared <|
                    Shared.AddNotification
                        { message = "Error Successfully Submitted"
                        , notificationType = Notification.Success
                        }
                ]
            )

        TransitionMsg transition ->
            case transition of
                SubmitNewTargetParameters { newTargetRecognitionTime, newTargetTps } ->
                    let
                        ( _, stateCmd ) =
                            ((states shared).startPage ()).init
                    in
                    ( { model | trainerState = StartPage }
                    , Effect.batch
                        [ Effect.fromCmd stateCmd
                        , Effect.fromShared <|
                            Shared.ModifyUser
                                (User.changePLLTargetParameters
                                    { targetRecognitionTimeInSeconds = newTargetRecognitionTime
                                    , targetTps = newTargetTps
                                    }
                                    |> userModificationThatAlwaysSucceeds
                                )
                        ]
                    )

                GoToEditTargetParameters ->
                    let
                        ( stateModel, stateCmd ) =
                            ((states shared).pickTargetParametersPage ()).init
                    in
                    ( { model | trainerState = PickTargetParametersPage stateModel }
                    , Effect.fromCmd stateCmd
                    )

                InitiateTest Nothing ->
                    ( model
                    , Effect.fromCmd <|
                        Task.perform (Just >> InitiateTest >> TransitionMsg) Time.now
                    )

                InitiateTest (Just now) ->
                    case
                        PLLTrainer.TestCase.generate
                            { now = now
                            , overrideWithConstantValue = model.tESTONLY.nextTestCaseOverride
                            }
                            shared.user
                    of
                        Ok generator ->
                            let
                                oldTestOnly =
                                    model.tESTONLY

                                newCaseExtraState =
                                    { generator = generator }

                                gettingReadyExtraState =
                                    GettingReadyExtraState generator

                                ( trainerState, stateCmd ) =
                                    if PLLTrainer.TestCase.isNewCaseGenerator generator then
                                        ((states shared).newCasePage newCaseExtraState).init
                                            |> Tuple.mapFirst (always <| NewCasePage newCaseExtraState)

                                    else
                                        ((states shared).testRunning gettingReadyExtraState).init
                                            |> Tuple.mapFirst (\stateModel -> TestRunning stateModel gettingReadyExtraState)
                            in
                            ( { model
                                | trainerState = trainerState
                                , tESTONLY = { oldTestOnly | nextTestCaseOverride = Nothing }
                              }
                            , Effect.fromCmd stateCmd
                            )

                        Err cmd ->
                            ( model, Effect.fromCmd cmd )

                NewCaseGetReadyForTest generator ->
                    let
                        gettingReadyExtraState =
                            GettingReadyExtraState generator

                        ( stateModel, stateCmd ) =
                            ((states shared).testRunning gettingReadyExtraState).init
                    in
                    ( { model | trainerState = TestRunning stateModel gettingReadyExtraState }
                    , Effect.fromCmd stateCmd
                    )

                StartTest (NothingGenerated generator) ->
                    ( model
                    , Effect.fromCmd <|
                        Task.perform
                            (TransitionMsg << StartTest << TimestampGenerated generator)
                            Time.now
                    )

                StartTest (TimestampGenerated generator testTimestamp) ->
                    ( model
                    , Effect.fromCmd <|
                        Random.generate
                            (\testCase ->
                                TransitionMsg <|
                                    StartTest <|
                                        EverythingGenerated
                                            testTimestamp
                                            { isNew = PLLTrainer.TestCase.isNewCaseGenerator generator
                                            , testCase = testCase
                                            }
                            )
                            (PLLTrainer.TestCase.getGenerator generator)
                    )

                StartTest (EverythingGenerated testTimestamp testCase) ->
                    let
                        extraState =
                            TestRunningExtraState
                                { testTimestamp = testTimestamp
                                , memoizedCube = PLLTrainer.TestCase.toCube shared.user testCase.testCase
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
                                    (PLLTrainer.TestCase.toAlg
                                        { addFinalReorientationToAlgorithm = True }
                                        shared.user
                                        model.currentTestCase.testCase
                                    )
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
                                , preAUF = PLLTrainer.TestCase.preAUF model.currentTestCase.testCase
                                , postAUF = PLLTrainer.TestCase.postAUF model.currentTestCase.testCase
                                , resultInMilliseconds = TimeInterval.asMilliseconds result
                                }
                    in
                    handleEvaluate testResult model shared

                EvaluateWrong { testTimestamp } ->
                    let
                        testResult =
                            User.Wrong
                                { timestamp = testTimestamp
                                , preAUF = PLLTrainer.TestCase.preAUF model.currentTestCase.testCase
                                , postAUF = PLLTrainer.TestCase.postAUF model.currentTestCase.testCase
                                }
                    in
                    handleEvaluate testResult model shared

                AlgorithmPicked getNextTrainerState testResult algorithm ->
                    case
                        Cube.detectAUFs
                            { toMatchTo =
                                PLLTrainer.TestCase.toAlg
                                    { addFinalReorientationToAlgorithm = False }
                                    shared.user
                                    model.currentTestCase.testCase
                            , toDetectFor = algorithm
                            }
                    of
                        Nothing ->
                            ( model, Effect.fromCmd <| Ports.logError "the algorithm picked didn't match the case" )

                        Just ( correctedPreAUF, correctedPostAUF ) ->
                            case
                                PLLTrainer.TestCase.build
                                    shared.user
                                    correctedPreAUF
                                    (PLLTrainer.TestCase.pll model.currentTestCase.testCase)
                                    correctedPostAUF
                            of
                                Ok correctedTestCase ->
                                    let
                                        oldTestCase =
                                            model.currentTestCase

                                        correctedTestResult =
                                            case testResult of
                                                User.Correct parameters ->
                                                    User.Correct { parameters | preAUF = PLLTrainer.TestCase.preAUF correctedTestCase, postAUF = PLLTrainer.TestCase.postAUF correctedTestCase }

                                                User.Wrong parameters ->
                                                    User.Wrong { parameters | preAUF = PLLTrainer.TestCase.preAUF correctedTestCase, postAUF = PLLTrainer.TestCase.postAUF correctedTestCase }

                                        nextTrainerState =
                                            getNextTrainerState algorithm
                                    in
                                    ( { model
                                        | currentTestCase =
                                            { oldTestCase
                                                | testCase = correctedTestCase
                                            }
                                        , trainerState = Tuple.first nextTrainerState
                                      }
                                    , Effect.batch
                                        [ Tuple.second nextTrainerState
                                        , Effect.fromShared <|
                                            Shared.ModifyUser
                                                (User.changePLLAlgorithm
                                                    (PLLTrainer.TestCase.pll correctedTestCase)
                                                    algorithm
                                                    >> recordPLLTestResultWithErrorHandling
                                                        (PLLTrainer.TestCase.pll correctedTestCase)
                                                        correctedTestResult
                                                )
                                        ]
                                    )

                                Err cmd ->
                                    ( model, Effect.fromCmd cmd )

                AUFPreferencesPicked ( nextTrainerState, nextEffect ) ->
                    let
                        pll =
                            PLLTrainer.TestCase.pll model.currentTestCase.testCase
                    in
                    case PLL.Extra.isSymmetricPLL pll of
                        Nothing ->
                            ( model
                            , Effect.fromShared
                                (Shared.AddErrorPopup
                                    { userFacingErrorMessage = "Unexpected error occurred while saving AUF preferences"
                                    , developerErrorMessage = "Attempted to save AUF preferences for no symmetric PLL " ++ PLL.getLetters pll
                                    }
                                )
                            )

                        Just symPLL ->
                            ( { model | trainerState = nextTrainerState }
                            , Effect.batch
                                [ nextEffect
                                , Effect.fromShared <|
                                    Shared.ModifyUser <|
                                        userModificationThatAlwaysSucceeds
                                            (User.setPLLAUFPreferences
                                                symPLL
                                                (PLL.Extra.getDefaultPLLPreferences symPLL)
                                            )
                                ]
                            )

                StartAlgorithmDrills ->
                    ( { model
                        | trainerState = AlgorithmDrillerStatusPage
                        , maybeDrillerState =
                            Just
                                { correctAttemptsLeft = correctAttemptsRequiredForDriller
                                , previousTestResult = PLLTrainer.States.AlgorithmDrillerStatusPage.NoFailure
                                }
                        , expectedCubeState = Cube.solved
                      }
                    , Effect.none
                    )

                InitiateAlgorithmDrillerTest Nothing ->
                    ( model
                    , Effect.fromCmd <|
                        Task.perform (Just >> InitiateAlgorithmDrillerTest >> TransitionMsg) Time.now
                    )

                InitiateAlgorithmDrillerTest (Just now) ->
                    case
                        PLLTrainer.TestCase.generate
                            { now = now
                            , overrideWithConstantValue = Just model.currentTestCase.testCase
                            }
                            shared.user
                    of
                        Ok generator ->
                            let
                                extraState =
                                    GettingReadyExtraState generator

                                ( stateModel, stateCmd ) =
                                    ((states shared).testRunning extraState).init
                            in
                            ( { model | trainerState = TestRunning stateModel extraState }, Effect.fromCmd stateCmd )

                        Err cmd ->
                            ( model, Effect.fromCmd cmd )

                WrongButNoMoveApplied { nextTrainerState } ->
                    ( { model
                        | trainerState = Tuple.first nextTrainerState
                        , expectedCubeState =
                            model.expectedCubeState
                                |> Cube.applyAlgorithm
                                    (Algorithm.inverse <|
                                        PLLTrainer.TestCase.toAlg
                                            { addFinalReorientationToAlgorithm = True }
                                            shared.user
                                            model.currentTestCase.testCase
                                    )
                      }
                    , Tuple.second nextTrainerState
                    )

                WrongButExpectedStateWasReached { nextTrainerState } ->
                    ( { model
                        | trainerState = Tuple.first nextTrainerState
                      }
                    , Tuple.second nextTrainerState
                    )

                WrongAndUnrecoverable { nextTrainerState } ->
                    ( { model
                        | trainerState = Tuple.first nextTrainerState
                        , expectedCubeState = Cube.solved
                      }
                    , Tuple.second nextTrainerState
                    )

        StateMsg stateMsg ->
            Tuple.mapSecond Effect.fromCmd <|
                handleStateMsgBoilerplate shared model stateMsg

        InternalMsg internalMsg ->
            case internalMsg of
                TESTONLYCurrentTestCaseRequested ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.tESTONLYEmitCurrentTestCase (PLLTrainer.TestCase.toTriple model.currentTestCase.testCase)
                    )

                TESTONLYSetTestCase (Ok (( pre, pll, post ) as testCaseTriple)) ->
                    case
                        PLLTrainer.TestCase.build shared.user pre pll post
                    of
                        Ok testCase ->
                            let
                                withUpdatedTestCase =
                                    { model
                                        | currentTestCase =
                                            { testCase = testCase
                                            , isNew = User.pllTestCaseIsNewForUser testCaseTriple shared.user
                                            }
                                    }

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

                        Err cmd ->
                            ( model, Effect.fromCmd cmd )

                TESTONLYSetTestCase (Err decodeError) ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.logError
                            ("Error in test only set test case: "
                                ++ Json.Decode.errorToString decodeError
                            )
                    )

                TESTONLYOverrideNextTestCase (Ok ( pre, pll, post )) ->
                    case
                        PLLTrainer.TestCase.build shared.user pre pll post
                    of
                        Ok testCaseOverride ->
                            let
                                oldTestOnly =
                                    model.tESTONLY
                            in
                            ( { model | tESTONLY = { oldTestOnly | nextTestCaseOverride = Just testCaseOverride } }, Effect.none )

                        Err cmd ->
                            ( model, Effect.fromCmd cmd )

                TESTONLYOverrideNextTestCase (Err decodeError) ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.logError
                            ("Error in test only override next test case: "
                                ++ Json.Decode.errorToString decodeError
                            )
                    )

                TESTONLYOverrideCubeDisplayAngle newDisplayAngle ->
                    ( model, Effect.fromShared (Shared.TESTONLYOverrideDisplayAngle newDisplayAngle) )

                TESTONLYSetCubeSizeOverride size ->
                    ( model, Effect.fromShared (Shared.TESTONLYSetCubeSizeOverride size) )

                TESTONLYOverrideDisplayCubeAnnotations displayAnnotations ->
                    ( model, Effect.fromShared (Shared.TESTONLYOverrideDisplayCubeAnnotations displayAnnotations) )

                TESTONLYSetPLLAlgorithm ( Err pllError, _ ) ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.logError
                            ("Error in pll decode of test only set pll algorithm: "
                                ++ pllError
                            )
                    )

                TESTONLYSetPLLAlgorithm ( _, Err algorithmError ) ->
                    ( model
                    , Effect.fromCmd <|
                        Ports.logError
                            ("Error in algorithm parsing of test only set pll algorithm: "
                                ++ Algorithm.debugFromStringError algorithmError
                            )
                    )

                TESTONLYSetPLLAlgorithm ( Ok pll, Ok algorithm ) ->
                    let
                        cleanedUpAlgorithm =
                            PLLTrainer.States.PickAlgorithmPage.cleanUpAlgorithm algorithm
                    in
                    if not <| PLL.solvedBy cleanedUpAlgorithm pll then
                        ( model
                        , Effect.fromCmd <|
                            Ports.logError
                                "algorithm given in test only set pll algorithm didn't match the pll"
                        )

                    else
                        ( model
                        , Effect.fromShared <|
                            Shared.ModifyUser
                                (User.changePLLAlgorithm
                                    pll
                                    cleanedUpAlgorithm
                                    >> (\x -> ( x, Nothing ))
                                )
                        )

                TESTONLYSetMultiplePLLAlgorithms (Err err) ->
                    let
                        errorMessage =
                            case err of
                                Ports.ErrorString x ->
                                    x

                                Ports.AlgorithmError { pllString } algError ->
                                    "Error in algorithm parsing of test only set multiple pll algorithms for pll "
                                        ++ pllString
                                        ++ ": "
                                        ++ Algorithm.debugFromStringError algError
                    in
                    ( model, Effect.fromCmd <| Ports.logError errorMessage )

                TESTONLYSetMultiplePLLAlgorithms (Ok pllAlgPairs) ->
                    let
                        modifyUserResult =
                            pllAlgPairs
                                |> List.foldl
                                    (\( pll, algorithm ) curResult ->
                                        case curResult of
                                            Err x ->
                                                Err x

                                            Ok curModification ->
                                                let
                                                    cleanedUpAlgorithm =
                                                        PLLTrainer.States.PickAlgorithmPage.cleanUpAlgorithm algorithm
                                                in
                                                if not <| PLL.solvedBy cleanedUpAlgorithm pll then
                                                    Err ("algorithm given in test only set multiple pll algorithms didn't match the pll " ++ PLL.getLetters pll)

                                                else
                                                    Ok
                                                        (curModification
                                                            >> User.changePLLAlgorithm
                                                                pll
                                                                cleanedUpAlgorithm
                                                        )
                                    )
                                    (Ok identity)
                    in
                    case modifyUserResult of
                        Ok modifyUser ->
                            ( model
                            , Effect.fromShared <|
                                Shared.ModifyUser (modifyUser >> (\x -> ( x, Nothing )))
                            )

                        Err err ->
                            ( model
                            , Effect.fromCmd <|
                                Ports.logError err
                            )

        NoOp ->
            ( model, Effect.none )


handleEvaluate : User.TestResult -> Model -> Shared.Model -> ( Model, Effect Msg )
handleEvaluate testResult model shared =
    let
        -- Because of the way it needs to be built up, the navigation is in the opposite
        -- direction of this let block. We start at the end and wrap it in each following step
        -- with a possible previous step
        normalCorrectOrWrongState =
            case testResult of
                User.Correct _ ->
                    let
                        ( _, stateCmd ) =
                            ((states shared).correctPage model ()).init
                    in
                    ( CorrectPage, Effect.fromCmd stateCmd )

                User.Wrong _ ->
                    let
                        ( _, stateCmd ) =
                            ((states shared).wrongPage model ()).init
                    in
                    ( WrongPage, Effect.fromCmd stateCmd )

        withDrillerIncludedAndState =
            case model.maybeDrillerState of
                Just { correctAttemptsLeft } ->
                    case testResult of
                        User.Correct _ ->
                            \algorithm ->
                                if wasCorrectTestFastEnoughToBeLearned shared.user algorithm testResult then
                                    if correctAttemptsLeft > 1 then
                                        ( ( AlgorithmDrillerStatusPage, Effect.none )
                                        , Just
                                            { correctAttemptsLeft = correctAttemptsLeft - 1
                                            , previousTestResult = PLLTrainer.States.AlgorithmDrillerStatusPage.NoFailure
                                            }
                                        )

                                    else
                                        ( ( AlgorithmDrillerSuccessPage, Effect.none ), Nothing )

                                else
                                    ( ( AlgorithmDrillerStatusPage, Effect.none )
                                    , Just
                                        { correctAttemptsLeft = correctAttemptsRequiredForDriller
                                        , previousTestResult = PLLTrainer.States.AlgorithmDrillerStatusPage.CorrectButSlowFailure
                                        }
                                    )

                        User.Wrong _ ->
                            always
                                ( ( AlgorithmDrillerStatusPage, Effect.none )
                                , Just
                                    { correctAttemptsLeft = correctAttemptsRequiredForDriller
                                    , previousTestResult = PLLTrainer.States.AlgorithmDrillerStatusPage.WrongFailure
                                    }
                                )

                Nothing ->
                    if not model.currentTestCase.isNew then
                        always ( normalCorrectOrWrongState, Nothing )

                    else
                        case testResult of
                            User.Correct _ ->
                                \algorithm ->
                                    ( if wasCorrectTestFastEnoughToBeLearned shared.user algorithm testResult then
                                        normalCorrectOrWrongState

                                      else
                                        ( AlgorithmDrillerExplanationPage { testResult = testResult }, Effect.none )
                                    , Nothing
                                    )

                            User.Wrong _ ->
                                always
                                    ( ( AlgorithmDrillerExplanationPage { testResult = testResult }, Effect.none )
                                    , Nothing
                                    )

        withPickAUFPreferencesIncludedAndDrillerState =
            \algorithm ->
                let
                    ( withDrillerIncluded, newDrillerState_ ) =
                        withDrillerIncludedAndState algorithm

                    maybeSymPLL =
                        PLL.Extra.isSymmetricPLL
                            (PLLTrainer.TestCase.pll model.currentTestCase.testCase)

                    aufPreferences =
                        maybeSymPLL
                            |> Maybe.andThen
                                (\symPLL ->
                                    User.getPLLAUFPreferences
                                        symPLL
                                        shared.user
                                )
                in
                if maybeSymPLL /= Nothing && aufPreferences == Nothing then
                    ( ( PickAUFPreferencesPage
                            { nextTrainerState = withDrillerIncluded
                            }
                      , Effect.none
                      )
                    , newDrillerState_
                    )

                else
                    ( withDrillerIncluded, newDrillerState_ )

        ( withPickAlgorithmIncluded, maybeRecordResultEffect, newDrillerState ) =
            case User.getPLLAlgorithm (PLLTrainer.TestCase.pll model.currentTestCase.testCase) shared.user of
                Just algorithm ->
                    let
                        ( withPickAUFPreferencesIncluded, newDrillerState_ ) =
                            withPickAUFPreferencesIncludedAndDrillerState algorithm
                    in
                    ( withPickAUFPreferencesIncluded
                    , if model.maybeDrillerState == Nothing then
                        Effect.fromShared <|
                            Shared.ModifyUser <|
                                recordPLLTestResultWithErrorHandling
                                    (PLLTrainer.TestCase.pll model.currentTestCase.testCase)
                                    testResult

                      else
                        Effect.none
                    , newDrillerState_
                    )

                Nothing ->
                    let
                        extraState =
                            { getNextTrainerState = withPickAUFPreferencesIncludedAndDrillerState >> Tuple.first
                            , testResult = testResult
                            }

                        ( stateModel, stateCmd ) =
                            ((states shared).pickAlgorithmPage model extraState).init
                    in
                    ( ( PickAlgorithmPage stateModel extraState
                      , Effect.fromCmd stateCmd
                      )
                    , Effect.none
                    , Nothing
                    )

        withEverythingIncluded =
            case testResult of
                User.Correct _ ->
                    withPickAlgorithmIncluded

                User.Wrong _ ->
                    let
                        extraState =
                            { nextTrainerState = withPickAlgorithmIncluded
                            }

                        ( _, stateCmd ) =
                            ((states shared).typeOfWrongPage model extraState).init
                    in
                    ( TypeOfWrongPage extraState
                    , Effect.fromCmd stateCmd
                    )
    in
    ( { model
        | trainerState = Tuple.first withEverythingIncluded
        , maybeDrillerState = newDrillerState
      }
    , Effect.batch
        [ Tuple.second withEverythingIncluded
        , maybeRecordResultEffect
        ]
    )


{-| The function is only meant to be called with a correct test result, so always
returns false for a wrong test result, it just makes the parameter passing cleaner
-}
wasCorrectTestFastEnoughToBeLearned : User -> Algorithm -> User.TestResult -> Bool
wasCorrectTestFastEnoughToBeLearned user algorithm testResult =
    case testResult of
        User.Correct { resultInMilliseconds, preAUF, postAUF } ->
            let
                { recognitionTimeInSeconds, tps } =
                    User.getPLLTargetParameters user

                targetTimeInSeconds =
                    recognitionTimeInSeconds + (Algorithm.Extra.complexity ( preAUF, postAUF ) algorithm / tps)
            in
            toFloat resultInMilliseconds <= (targetTimeInSeconds * 1000)

        User.Wrong _ ->
            False


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


userModificationThatAlwaysSucceeds : (User -> User) -> (User -> ( User, Maybe { errorMessage : String } ))
userModificationThatAlwaysSucceeds fn =
    fn >> (\newUser -> ( newUser, Nothing ))



-- SUBSCRIPTIONS


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    Sub.batch
        [ handleStateSubscriptionsBoilerplate shared model
            |> PLLTrainer.Subscription.getSub
        , Ports.onTESTONLYSetTestCase (InternalMsg << TESTONLYSetTestCase)
        , Ports.onTESTONLYOverrideNextTestCase (InternalMsg << TESTONLYOverrideNextTestCase)
        , Ports.onTESTONLYOverrideCubeDisplayAngle (InternalMsg << TESTONLYOverrideCubeDisplayAngle)
        , Ports.onTESTONLYOverrideDisplayCubeAnnotations (InternalMsg << TESTONLYOverrideDisplayCubeAnnotations)
        , Ports.onTESTONLYSetCubeSizeOverride (InternalMsg << TESTONLYSetCubeSizeOverride)
        , Ports.onTESTONLYSetPLLAlgorithm (InternalMsg << TESTONLYSetPLLAlgorithm)
        , Ports.onTESTONLYSetMultiplePLLAlgorithmsPort (InternalMsg << TESTONLYSetMultiplePLLAlgorithms)
        , Ports.onTESTONLYCurrentTestCaseRequested (InternalMsg TESTONLYCurrentTestCaseRequested)
        ]



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        stateView =
            handleStateViewBoilerplate shared model

        testOnlyStateAttributeValue =
            getTestOnlyStateAttributeValue model

        extraTopLevelAttributes =
            [ Css.testid "pll-trainer-root"
            , Element.htmlAttribute <|
                Html.Attributes.attribute
                    "__test-helper__state"
                    testOnlyStateAttributeValue
            ]

        subscription =
            handleStateSubscriptionsBoilerplate shared model

        pageSubtitle =
            Nothing
    in
    PLLTrainer.State.stateViewToGlobalView
        pageSubtitle
        subscription
        extraTopLevelAttributes
        stateView



-- BOILERPLATE


type alias StateBuilder localMsg model extraState =
    extraState
    -> PLLTrainer.State.State Msg localMsg model


states :
    Shared.Model
    -- Note that we don't pass in the model here but only to the ones
    -- that need it since some states want to be able to be instantiated
    -- without a model in place, for example in the init function
    ->
        { pickTargetParametersPage :
            StateBuilder
                PLLTrainer.States.PickTargetParametersPage.Msg
                PLLTrainer.States.PickTargetParametersPage.Model
                ()
        , startPage : StateBuilder () () ()
        , newCasePage : StateBuilder () () NewCaseExtraState
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
        , pickAUFPreferencesPage : StateBuilder () () PickAUFPreferencesExtraState
        , algorithmDrillerExplanationPage :
            Model
            -> StateBuilder () () AlgorithmDrillerExplanationExtraState
        , algorithmDrillerStatusPage : Model -> StateBuilder () () ()
        , algorithmDrillerSuccessPage : StateBuilder () () ()
        , correctPage : Model -> StateBuilder () () ()
        , typeOfWrongPage : Model -> StateBuilder () () TypeOfWrongExtraState
        , wrongPage : Model -> StateBuilder () () ()
        }
states shared =
    { pickTargetParametersPage =
        always <|
            PLLTrainer.States.PickTargetParametersPage.state
                shared
                { submit = TransitionMsg << SubmitNewTargetParameters
                }
                (StateMsg << PickTargetParametersMsg)
    , startPage =
        always <|
            PLLTrainer.States.StartPage.state
                shared
                { startTest = TransitionMsg (InitiateTest Nothing)
                , editTargetParameters = TransitionMsg GoToEditTargetParameters
                , noOp = NoOp
                }
    , newCasePage =
        \{ generator } ->
            PLLTrainer.States.NewCasePage.state
                shared
                { startTest = TransitionMsg <| NewCaseGetReadyForTest generator
                , noOp = NoOp
                }
    , testRunning =
        \extraState ->
            let
                arguments =
                    case extraState of
                        GettingReadyExtraState generator ->
                            PLLTrainer.States.TestRunning.GetReadyArgument
                                { startTest = TransitionMsg <| StartTest <| NothingGenerated generator }

                        TestRunningExtraState { memoizedCube, testTimestamp } ->
                            PLLTrainer.States.TestRunning.TestRunningArgument
                                { memoizedCube = memoizedCube
                                , endTest = TransitionMsg << EndTest { testTimestamp = testTimestamp }
                                }
            in
            PLLTrainer.States.TestRunning.state
                shared
                arguments
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
        \model { getNextTrainerState, testResult } ->
            PLLTrainer.States.PickAlgorithmPage.state
                { currentTestCase = model.currentTestCase.testCase
                , testCaseResult = testResult
                }
                shared
                { continue = TransitionMsg << AlgorithmPicked getNextTrainerState testResult
                , noOp = NoOp
                }
                (StateMsg << PickAlgorithmMsg)
    , pickAUFPreferencesPage =
        \{ nextTrainerState } ->
            PLLTrainer.States.PickAUFPreferencesPage.state
                shared
                { continue = TransitionMsg <| AUFPreferencesPicked nextTrainerState
                , noOp = NoOp
                }
    , algorithmDrillerExplanationPage =
        \model extraState ->
            PLLTrainer.States.AlgorithmDrillerExplanationPage.state
                shared
                { startDrills = TransitionMsg StartAlgorithmDrills
                , noOp = NoOp
                }
                { testCase = model.currentTestCase.testCase
                , wasCorrect =
                    case extraState.testResult of
                        User.Correct _ ->
                            True

                        User.Wrong _ ->
                            False
                , sendError = SubmitError
                }
    , algorithmDrillerStatusPage =
        \model _ ->
            PLLTrainer.States.AlgorithmDrillerStatusPage.state
                shared
                { startTest = TransitionMsg (InitiateAlgorithmDrillerTest Nothing)
                , noOp = NoOp
                }
                { expectedCube = model.expectedCubeState
                , correctAttemptsLeft =
                    model.maybeDrillerState
                        |> Maybe.map .correctAttemptsLeft
                        |> Maybe.withDefault correctAttemptsRequiredForDriller
                , previousTestResult =
                    model.maybeDrillerState
                        |> Maybe.map .previousTestResult
                        |> Maybe.withDefault PLLTrainer.States.AlgorithmDrillerStatusPage.NoFailure
                }
    , algorithmDrillerSuccessPage =
        always <|
            PLLTrainer.States.AlgorithmDrillerSuccessPage.state
                shared
                { startTest = TransitionMsg (InitiateTest Nothing)
                , noOp = NoOp
                }
    , correctPage =
        \model _ ->
            PLLTrainer.States.CorrectPage.state
                shared
                { wasNewCase = model.currentTestCase.isNew }
                { startTest = TransitionMsg (InitiateTest Nothing)
                , noOp = NoOp
                }
    , typeOfWrongPage =
        \model extraState ->
            PLLTrainer.States.TypeOfWrongPage.state
                shared
                { noMoveWasApplied = TransitionMsg (WrongButNoMoveApplied { nextTrainerState = extraState.nextTrainerState })
                , expectedStateWasReached = TransitionMsg (WrongButExpectedStateWasReached { nextTrainerState = extraState.nextTrainerState })
                , cubeUnrecoverable = TransitionMsg (WrongAndUnrecoverable { nextTrainerState = extraState.nextTrainerState })
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , testCase = model.currentTestCase.testCase
                }
    , wrongPage =
        \model _ ->
            PLLTrainer.States.WrongPage.state
                shared
                { startNextTest = TransitionMsg (InitiateTest Nothing)
                , noOp = NoOp
                }
                { expectedCubeState = model.expectedCubeState
                , testCase = model.currentTestCase.testCase
                , sendError = SubmitError
                }
    }


handleStateMsgBoilerplate :
    Shared.Model
    -> Model
    -> StateMsg
    -> ( Model, Cmd Msg )
handleStateMsgBoilerplate shared model stateMsg =
    case ( stateMsg, model.trainerState ) of
        ( PickTargetParametersMsg localMsg, PickTargetParametersPage localModel ) ->
            ((states shared).pickTargetParametersPage ()).update localMsg localModel
                |> Tuple.mapFirst
                    (\newStateModel ->
                        { model | trainerState = PickTargetParametersPage newStateModel }
                    )

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

        NewCasePage _ ->
            "NewCasePage"

        TestRunning _ extraState ->
            "TestRunning: "
                ++ (case extraState of
                        GettingReadyExtraState _ ->
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

        PickAUFPreferencesPage _ ->
            "PickAUFPreferencesPage"

        AlgorithmDrillerExplanationPage _ ->
            "AlgorithmDrillerExplanationPage"

        AlgorithmDrillerStatusPage ->
            "AlgorithmDrillerStatusPage"

        AlgorithmDrillerSuccessPage ->
            "AlgorithmDrillerSuccessPage"

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

        NewCasePage extraState ->
            ((states shared).newCasePage extraState).subscriptions ()

        TestRunning stateModel extraState ->
            ((states shared).testRunning extraState).subscriptions stateModel

        EvaluateResult stateModel extraState ->
            ((states shared).evaluateResult model extraState).subscriptions stateModel

        PickAlgorithmPage stateModel extraState ->
            ((states shared).pickAlgorithmPage model extraState).subscriptions stateModel

        PickAUFPreferencesPage extraState ->
            ((states shared).pickAUFPreferencesPage extraState).subscriptions ()

        AlgorithmDrillerExplanationPage extraState ->
            ((states shared).algorithmDrillerExplanationPage model extraState).subscriptions ()

        AlgorithmDrillerStatusPage ->
            ((states shared).algorithmDrillerStatusPage model ()).subscriptions ()

        AlgorithmDrillerSuccessPage ->
            ((states shared).algorithmDrillerSuccessPage ()).subscriptions ()

        CorrectPage ->
            ((states shared).correctPage model ()).subscriptions ()

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

        NewCasePage extraState ->
            ((states shared).newCasePage extraState).view ()

        TestRunning stateModel extraState ->
            ((states shared).testRunning extraState).view stateModel

        EvaluateResult stateModel extraState ->
            ((states shared).evaluateResult model extraState).view stateModel

        TypeOfWrongPage extraState ->
            ((states shared).typeOfWrongPage model extraState).view ()

        PickAlgorithmPage stateModel extraState ->
            ((states shared).pickAlgorithmPage model extraState).view stateModel

        PickAUFPreferencesPage extraState ->
            ((states shared).pickAUFPreferencesPage extraState).view ()

        AlgorithmDrillerExplanationPage extraState ->
            ((states shared).algorithmDrillerExplanationPage model extraState).view ()

        AlgorithmDrillerSuccessPage ->
            ((states shared).algorithmDrillerSuccessPage ()).view ()

        AlgorithmDrillerStatusPage ->
            ((states shared).algorithmDrillerStatusPage model ()).view ()

        CorrectPage ->
            ((states shared).correctPage model ()).view ()

        WrongPage ->
            ((states shared).wrongPage model ()).view ()


getTestOnlyStateAttributeValue : Model -> String
getTestOnlyStateAttributeValue model =
    case model.trainerState of
        PickTargetParametersPage _ ->
            "pick-target-parameters-page"

        StartPage ->
            "start-page"

        NewCasePage _ ->
            "new-case-page"

        TestRunning _ extraState ->
            case extraState of
                GettingReadyExtraState _ ->
                    "get-ready-state"

                TestRunningExtraState _ ->
                    "test-running-state"

        EvaluateResult _ _ ->
            "evaluate-result-page"

        TypeOfWrongPage _ ->
            "type-of-wrong-page"

        PickAlgorithmPage _ _ ->
            "pick-algorithm-page"

        PickAUFPreferencesPage _ ->
            "pick-auf-preferences-page"

        AlgorithmDrillerExplanationPage _ ->
            "algorithm-driller-explanation-page"

        AlgorithmDrillerStatusPage ->
            "algorithm-driller-status-page"

        AlgorithmDrillerSuccessPage ->
            "algorithm-driller-success-page"

        CorrectPage ->
            "correct-page"

        WrongPage ->
            "wrong-page"


uniquePageIdentifier : Model -> String
uniquePageIdentifier model =
    case model.trainerState of
        PickTargetParametersPage _ ->
            "pick-target-parameters-page"

        StartPage ->
            "start-page"

        NewCasePage _ ->
            "new-case-page"

        TestRunning _ _ ->
            "test-running"

        EvaluateResult _ _ ->
            "evaluate-result-page"

        TypeOfWrongPage _ ->
            "type-of-wrong-page"

        PickAlgorithmPage _ _ ->
            "pick-algorithm-page"

        PickAUFPreferencesPage _ ->
            "pick-auf-preferences-page"

        AlgorithmDrillerExplanationPage _ ->
            "algorithm-driller-explanation-page"

        AlgorithmDrillerStatusPage ->
            "algorithm-driller-status-page"

        AlgorithmDrillerSuccessPage ->
            "algorithm-driller-success-page"

        CorrectPage ->
            "correct-page"

        WrongPage ->
            "wrong-page"
