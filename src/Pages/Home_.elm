module Pages.Home_ exposing (Model, Msg, page)

import Algorithm exposing (Algorithm)
import Browser.Events
import Cube exposing (Cube)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Gen.Params.Home_ exposing (Params)
import Html.Events
import Json.Decode
import List.Nonempty
import PLL exposing (PLL)
import Page
import Ports
import Process
import Random
import Request
import Shared
import Task
import Time
import UI
import Utils.Css exposing (htmlTestid, testid)
import Utils.TimeInterval as TimeInterval exposing (TimeInterval)
import View exposing (View)
import ViewCube
import ViewportSize exposing (ViewportSize)
import WebResource


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init
        , update = update
        , view = view shared.palette shared.hardwareAvailable shared.viewportSize
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { trainerState : TrainerState
    , expectedCube : Cube
    }


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning Time.Posix TimeInterval TestCase
    | EvaluatingResult
        { spacePressStarted : Bool
        , wPressStarted : Bool
        , tooEarlyToTransition : Bool
        , result : TimeInterval
        , testCase : TestCase
        }
    | TypeOfWrongPage TestCase
    | WrongPage TestCase
    | CorrectPage


type alias TestCase =
    ( Algorithm, PLL, Algorithm )


toAlg : TestCase -> Algorithm.Algorithm
toAlg ( preauf, pll, postauf ) =
    preauf
        |> Algorithm.append (PLL.getAlg pll)
        |> Algorithm.append postauf


generateTestCase : Random.Generator TestCase
generateTestCase =
    Random.map3 (\a b c -> ( a, b, c ))
        (List.Nonempty.sample Algorithm.aufs)
        (List.Nonempty.sample PLL.allPlls)
        (List.Nonempty.sample Algorithm.aufs)


init : ( Model, Cmd msg )
init =
    { trainerState = StartPage
    , expectedCube = Cube.solved
    }
        |> (\x -> Tuple.pair x Cmd.none)



-- UPDATE


type Msg
    = BetweenTestsMessage BetweenTestsMsg
    | GetReadyMessage GetReadyMsg
    | TestRunningMessage TestRunningMsg
    | EvaluateResultMessage EvaluateResultMsg
    | TypeOfWrongMessage TypeOfWrongMsg


type BetweenTestsMsg
    = StartTestGetReady
    | DoNothingBetweenTests


type TypeOfWrongMsg
    = NoMoveWasApplied
    | ExpectedStateWasReached
    | CubeStateIsUnrecoverable
    | DoNothingTypeOfWrong


type GetReadyMsg
    = StartTest TestStartData


type TestStartData
    = NothingGenerated
    | TestCaseGenerated TestCase
    | EverythingGenerated TestCase Time.Posix


type TestRunningMsg
    = MillisecondsPassed Float
    | EndTest (Maybe Time.Posix)


type EvaluateResultMsg
    = NowLateEnoughToTransition
    | SpaceStarted
    | WStarted
    | EvaluateCorrect
    | EvaluateWrong
    | DoNothingEvaluateResult


update : Msg -> Model -> ( Model, Cmd Msg )
update messageCategory model =
    case ( messageCategory, model.trainerState ) of
        ( BetweenTestsMessage msg, StartPage ) ->
            updateBetweenTests model msg

        ( BetweenTestsMessage msg, CorrectPage ) ->
            updateBetweenTests model msg

        ( BetweenTestsMessage msg, WrongPage _ ) ->
            updateBetweenTests model msg

        ( GetReadyMessage msg, GetReadyScreen ) ->
            Tuple.mapSecond (Cmd.map GetReadyMessage) <|
                case msg of
                    StartTest NothingGenerated ->
                        ( model, Random.generate (\alg -> StartTest (TestCaseGenerated alg)) generateTestCase )

                    StartTest (TestCaseGenerated alg) ->
                        ( model, Task.perform (\time -> StartTest (EverythingGenerated alg time)) Time.now )

                    StartTest (EverythingGenerated alg startTime) ->
                        ( { model | trainerState = TestRunning startTime TimeInterval.zero alg }, Cmd.none )

        ( TestRunningMessage msg, TestRunning startTime intervalElapsed testCase ) ->
            case msg of
                EndTest Nothing ->
                    ( model, Task.perform (\time -> TestRunningMessage <| EndTest (Just time)) Time.now )

                EndTest (Just endTime) ->
                    ( { model
                        | trainerState =
                            EvaluatingResult
                                { spacePressStarted = False
                                , wPressStarted = False
                                , tooEarlyToTransition = True
                                , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                                , testCase = testCase
                                }
                        , expectedCube = model.expectedCube |> Cube.applyAlgorithm (toAlg testCase)
                      }
                    , Task.perform (always <| EvaluateResultMessage NowLateEnoughToTransition) (Process.sleep 200)
                    )

                MillisecondsPassed timeDelta ->
                    ( { model | trainerState = TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed) testCase }, Cmd.none )

        ( EvaluateResultMessage msg, EvaluatingResult keyStates ) ->
            Tuple.mapSecond (Cmd.map EvaluateResultMessage) <|
                case msg of
                    NowLateEnoughToTransition ->
                        ( { model | trainerState = EvaluatingResult { keyStates | tooEarlyToTransition = False } }, Cmd.none )

                    SpaceStarted ->
                        ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                    WStarted ->
                        ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                    EvaluateCorrect ->
                        ( { model | trainerState = CorrectPage }, Cmd.none )

                    EvaluateWrong ->
                        ( { model | trainerState = TypeOfWrongPage keyStates.testCase }, Cmd.none )

                    DoNothingEvaluateResult ->
                        ( model, Cmd.none )

        ( TypeOfWrongMessage msg, TypeOfWrongPage testCase ) ->
            Tuple.mapSecond (Cmd.map TypeOfWrongMessage) <|
                case msg of
                    NoMoveWasApplied ->
                        ( { model | trainerState = WrongPage testCase, expectedCube = model.expectedCube |> Cube.applyAlgorithm (Algorithm.inverse <| toAlg testCase) }, Cmd.none )

                    ExpectedStateWasReached ->
                        ( { model | trainerState = WrongPage testCase }, Cmd.none )

                    CubeStateIsUnrecoverable ->
                        ( { model | trainerState = WrongPage testCase, expectedCube = Cube.solved }, Cmd.none )

                    DoNothingTypeOfWrong ->
                        ( model, Cmd.none )

        ( msg, trainerState ) ->
            ( model
            , let
                msgString =
                    case msg of
                        BetweenTestsMessage _ ->
                            "BetweenTestsMessage"

                        GetReadyMessage _ ->
                            "GetReadyMessage"

                        TestRunningMessage _ ->
                            "TestRunningMessage"

                        EvaluateResultMessage evalMsg ->
                            "EvaluateResultMessage: "
                                ++ (case evalMsg of
                                        NowLateEnoughToTransition ->
                                            "NowLateEnoughToTransition"

                                        _ ->
                                            "A yet unimplemented stringify"
                                   )

                        TypeOfWrongMessage _ ->
                            "TypeOfWrongMessage"

                trainerStateString =
                    case trainerState of
                        StartPage ->
                            "StartPage"

                        GetReadyScreen ->
                            "GetReadyScreen"

                        TestRunning _ _ _ ->
                            "TestRunning"

                        EvaluatingResult _ ->
                            "EvaluatingResult"

                        TypeOfWrongPage _ ->
                            "TypeOfWrongPage"

                        WrongPage _ ->
                            "WrongPage"

                        CorrectPage ->
                            "CorrectPage"
              in
              Ports.logError
                ("Message received during unexpected state: "
                    ++ "("
                    ++ msgString
                    ++ ", "
                    ++ trainerStateString
                    ++ ")"
                )
            )


updateBetweenTests : Model -> BetweenTestsMsg -> ( Model, Cmd Msg )
updateBetweenTests model msg =
    case msg of
        StartTestGetReady ->
            ( { model | trainerState = GetReadyScreen }
            , Task.perform (always <| GetReadyMessage (StartTest NothingGenerated)) <| Process.sleep 1000
            )

        DoNothingBetweenTests ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        betweenTestsSubscriptions =
            Sub.map BetweenTestsMessage <|
                Browser.Events.onKeyUp <|
                    Json.Decode.map
                        (\key ->
                            if key == Space then
                                StartTestGetReady

                            else
                                DoNothingBetweenTests
                        )
                        decodeNonRepeatedKeyEvent
    in
    case model.trainerState of
        StartPage ->
            betweenTestsSubscriptions

        CorrectPage ->
            betweenTestsSubscriptions

        WrongPage _ ->
            betweenTestsSubscriptions

        TypeOfWrongPage _ ->
            Sub.map TypeOfWrongMessage <|
                Browser.Events.onKeyUp <|
                    Json.Decode.map
                        (\key ->
                            case key of
                                One ->
                                    NoMoveWasApplied

                                Two ->
                                    ExpectedStateWasReached

                                Three ->
                                    CubeStateIsUnrecoverable

                                _ ->
                                    DoNothingTypeOfWrong
                        )
                        decodeNonRepeatedKeyEvent

        GetReadyScreen ->
            Sub.none

        TestRunning _ _ _ ->
            Sub.map TestRunningMessage <|
                Sub.batch
                    [ Browser.Events.onKeyDown <|
                        Json.Decode.map
                            (always <| EndTest Nothing)
                            decodeNonRepeatedKeyEvent
                    , Browser.Events.onMouseDown <|
                        Json.Decode.succeed <|
                            EndTest Nothing
                    , Browser.Events.onAnimationFrameDelta MillisecondsPassed
                    ]

        EvaluatingResult { tooEarlyToTransition, spacePressStarted, wPressStarted } ->
            Sub.map EvaluateResultMessage <|
                if tooEarlyToTransition then
                    Sub.none

                else
                    Sub.batch
                        [ Browser.Events.onKeyDown <|
                            Json.Decode.map
                                (\key ->
                                    case key of
                                        Space ->
                                            SpaceStarted

                                        W ->
                                            WStarted

                                        _ ->
                                            DoNothingEvaluateResult
                                )
                                decodeNonRepeatedKeyEvent
                        , Browser.Events.onKeyUp <|
                            Json.Decode.map
                                (\key ->
                                    case key of
                                        Space ->
                                            if spacePressStarted then
                                                EvaluateCorrect

                                            else
                                                DoNothingEvaluateResult

                                        W ->
                                            if wPressStarted then
                                                EvaluateWrong

                                            else
                                                DoNothingEvaluateResult

                                        _ ->
                                            DoNothingEvaluateResult
                                )
                                decodeNonRepeatedKeyEvent
                        ]


type Key
    = Space
    | W
    | One
    | Two
    | Three
    | SomeKey String


decodeNonRepeatedKeyEvent : Json.Decode.Decoder Key
decodeNonRepeatedKeyEvent =
    let
        fields =
            Json.Decode.map2 Tuple.pair decodeKey decodeKeyRepeat
    in
    fields
        |> Json.Decode.andThen
            (\( key, isRepeated ) ->
                if isRepeated == True then
                    Json.Decode.fail "Was a repeated key press"

                else
                    Json.Decode.succeed key
            )


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Json.Decode.Decoder Key
decodeKey =
    Json.Decode.map toKey (Json.Decode.field "key" Json.Decode.string)


decodeKeyRepeat : Json.Decode.Decoder Bool
decodeKeyRepeat =
    Json.Decode.field "repeat" Json.Decode.bool


toKey : String -> Key
toKey keyString =
    case keyString of
        " " ->
            Space

        "w" ->
            W

        "W" ->
            W

        "1" ->
            One

        "2" ->
            Two

        "3" ->
            Three

        _ ->
            SomeKey keyString


topLevelEventListeners : Model -> View.TopLevelEventListeners Msg
topLevelEventListeners model =
    View.buildTopLevelEventListeners <|
        case model.trainerState of
            StartPage ->
                []

            GetReadyScreen ->
                []

            TestRunning _ _ _ ->
                List.map
                    (mapAttribute TestRunningMessage)
                    [ htmlAttribute <|
                        Html.Events.on "touchstart" <|
                            Json.Decode.succeed <|
                                EndTest Nothing
                    ]

            EvaluatingResult _ ->
                []

            TypeOfWrongPage _ ->
                []

            WrongPage _ ->
                []

            CorrectPage ->
                []



-- VIEW


view : UI.Palette -> Shared.HardwareAvailable -> ViewportSize -> Model -> View Msg
view palette hardwareAvailable viewportSize model =
    let
        shouldDisplayFeedbackButton =
            case model.trainerState of
                CorrectPage ->
                    True

                WrongPage _ ->
                    True

                TypeOfWrongPage _ ->
                    False

                StartPage ->
                    False

                GetReadyScreen ->
                    False

                TestRunning _ _ _ ->
                    False

                EvaluatingResult _ ->
                    False
    in
    { pageSubtitle = Nothing
    , topLevelEventListeners = topLevelEventListeners model
    , overlays =
        View.buildOverlays
            (if shouldDisplayFeedbackButton then
                [ overlayFeedbackButton viewportSize ]

             else
                []
            )
    , body = View.FullScreen <| viewFullScreen palette hardwareAvailable viewportSize model
    }


viewFullScreen : UI.Palette -> Shared.HardwareAvailable -> ViewportSize -> Model -> Element Msg
viewFullScreen palette hardwareAvailable viewportSize model =
    case model.trainerState of
        StartPage ->
            Element.map BetweenTestsMessage <|
                el
                    [ testid "start-page-container"
                    , centerY
                    , scrollbarY
                    , width fill
                    , UI.fontSize.large
                    ]
                <|
                    column
                        [ UI.spacing.small
                        , centerX
                        , width (fill |> maximum (ViewportSize.width viewportSize * 3 // 4))
                        , UI.paddingVertical.veryLarge
                        ]
                    <|
                        [ column
                            [ testid "welcome-text"
                            , Font.center
                            , centerX
                            , UI.spacing.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ]
                                [ text "Welcome!" ]
                            , paragraph []
                                [ text "This is a "
                                , UI.viewWebResourceLink palette WebResource.PLLExplanation "PLL"
                                , text " trainer which attempts to remove both the manual scrambling to create more flow, and to make practice closer to real life by timing from "
                                , UI.viewWebResourceLink palette WebResource.HomeGripExplanation "home grip"
                                , text
                                    ", and including recognition and pre- and post-"
                                , UI.viewWebResourceLink palette WebResource.AUFExplanation "AUF"
                                , text
                                    " in timing. Many improvements including intelligently displaying your weakest cases to enhance learning are planned!"
                                ]
                            ]
                        , UI.viewDivider palette
                        , paragraph
                            [ UI.fontSize.veryLarge
                            , centerX
                            , Font.center
                            , testid "cube-start-explanation"
                            , Region.heading 1
                            ]
                          <|
                            [ text "Orient Solved Cube Like This:" ]
                        , el
                            [ testid "cube-start-state"
                            , centerX
                            ]
                          <|
                            ViewCube.uFRWithLetters [] 200 model.expectedCube
                        , buttonWithShortcut
                            hardwareAvailable
                            [ testid "start-button"
                            , centerX
                            ]
                            { onPress = Just StartTestGetReady
                            , labelText = "Start"
                            , color = palette.primary
                            , keyboardShortcut = Space
                            }
                            UI.viewButton.large
                        , UI.viewDivider palette
                        , column
                            [ testid "instructions-text"
                            , Font.center
                            , centerX
                            , UI.spacing.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ] [ text "Instructions:" ]
                            , paragraph []
                                [ text "When you press the start button (or space) you will have a second to get your cube in "
                                , UI.viewWebResourceLink palette
                                    WebResource.HomeGripExplanation
                                    "home grip"
                                , text ". Then a "
                                , UI.viewWebResourceLink palette WebResource.PLLExplanation "PLL"
                                , text " case will show up and the timer will start. If you successfully recognize the case apply the moves to your cube that would solve the cube on screen (including pre- and post-"
                                , UI.viewWebResourceLink palette WebResource.AUFExplanation "AUF"
                                , text
                                    "), and then press anything to stop the timer. If you don't recognize the case just press anything when you are sure you can't recall it. Things to press include any keyboard key, the screen and your mouse/touchpad."
                                ]
                            , paragraph []
                                [ text "You will then be displayed how the cube should look if you applied the correct moves. Click the button labelled correct or wrong depending on whether your cube matches the one on screen, and if you got it correct, simply continue to the next case without any change to your cube!"
                                ]
                            , paragraph []
                                [ text "If you got it wrong you will have to solve the cube to reset it before being able to continue to the next case. Don't worry, you will be instructed through all this by the application."
                                ]
                            ]
                        , UI.viewDivider palette
                        , column
                            [ testid "learning-resources"
                            , centerX
                            , UI.spacing.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Region.heading 1, Font.center ] [ text "Learning Resources:" ]
                            , UI.viewUnorderedList [ centerX ]
                                [ paragraph []
                                    [ UI.viewWebResourceLink palette
                                        WebResource.TwoSidedPllRecognitionGuide
                                        "Two Sided PLL Recognition Guide"
                                    ]
                                , paragraph []
                                    [ UI.viewWebResourceLink palette WebResource.PLLAlgorithmsResource "Fast PLL Algorithms And Finger Tricks"
                                    ]
                                , paragraph []
                                    [ text "And just generally make sure you drill you algorithms until you can do them without looking!" ]
                                ]
                            ]
                        ]

        GetReadyScreen ->
            el
                [ testid "get-ready-container"
                , centerX
                , centerY
                ]
            <|
                paragraph
                    [ testid "get-ready-explanation"
                    , Font.size (ViewportSize.minDimension viewportSize * 2 // 9)
                    , Font.center
                    , UI.paddingAll.medium
                    ]
                    [ text "Go To Home Grip" ]

        TestRunning _ elapsedTime testCase ->
            Element.map TestRunningMessage <|
                column
                    [ testid "test-running-container"
                    , centerX
                    , centerY
                    , spacing (ViewportSize.minDimension viewportSize // 10)
                    ]
                    [ el [ centerX ] <|
                        ViewCube.uFRNoLetters [ htmlTestid "test-case" ] (ViewportSize.minDimension viewportSize // 2) <|
                            (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse (toAlg testCase)))
                    , el
                        [ testid "timer"
                        , centerX
                        , Font.size (ViewportSize.minDimension viewportSize // 5)
                        ]
                      <|
                        text <|
                            TimeInterval.displayOneDecimal elapsedTime
                    ]

        EvaluatingResult { result, tooEarlyToTransition } ->
            Element.map EvaluateResultMessage <|
                let
                    overallPadding =
                        ViewportSize.minDimension viewportSize // 20

                    cubeSize =
                        ViewportSize.minDimension viewportSize // 3

                    cubeSpacing =
                        ViewportSize.minDimension viewportSize // 15

                    timerSize =
                        ViewportSize.minDimension viewportSize // 6

                    buttonSpacing =
                        ViewportSize.minDimension viewportSize // 15

                    button =
                        \attributes ->
                            UI.viewButton.customSize (ViewportSize.minDimension viewportSize // 13)
                                (attributes
                                    ++ [ Font.center
                                       , width (px <| ViewportSize.minDimension viewportSize // 3)
                                       ]
                                )
                in
                column
                    [ testid "evaluate-test-result-container"
                    , centerX
                    , centerY
                    , height (fill |> maximum (ViewportSize.minDimension viewportSize))
                    , spaceEvenly
                    , padding overallPadding
                    ]
                    [ el
                        [ testid "time-result"
                        , centerX
                        , Font.size timerSize
                        ]
                      <|
                        text <|
                            TimeInterval.displayTwoDecimals result
                    , row
                        [ centerX
                        , spacing cubeSpacing
                        ]
                        [ ViewCube.uFRWithLetters [ htmlTestid "expected-cube-front" ] cubeSize model.expectedCube
                        , ViewCube.uBLWithLetters [ htmlTestid "expected-cube-back" ] cubeSize model.expectedCube
                        ]
                    , row [ centerX, spacing buttonSpacing ]
                        [ buttonWithShortcut
                            hardwareAvailable
                            [ testid "correct-button"
                            ]
                            { onPress =
                                if tooEarlyToTransition then
                                    Nothing

                                else
                                    Just EvaluateCorrect
                            , labelText = "Correct"
                            , color = palette.correct
                            , keyboardShortcut = Space
                            }
                            button
                        , buttonWithShortcut
                            hardwareAvailable
                            [ testid "wrong-button"
                            ]
                            { onPress =
                                if tooEarlyToTransition then
                                    Nothing

                                else
                                    Just EvaluateWrong
                            , labelText = "Wrong"
                            , keyboardShortcut = W
                            , color = palette.wrong
                            }
                            button
                        ]
                    ]

        CorrectPage ->
            Element.map BetweenTestsMessage <|
                column
                    [ testid "correct-container"
                    , centerX
                    , centerY
                    , spacing (ViewportSize.minDimension viewportSize // 20)
                    ]
                    [ el
                        [ centerX
                        , Font.size (ViewportSize.minDimension viewportSize // 20)
                        ]
                      <|
                        text "Correct!"
                    , el
                        [ centerX
                        , Font.size (ViewportSize.minDimension viewportSize // 20)
                        ]
                      <|
                        text "Continue When Ready"
                    , buttonWithShortcut
                        hardwareAvailable
                        [ testid "next-button"
                        , centerX
                        ]
                        { onPress = Just StartTestGetReady
                        , labelText = "Next"
                        , keyboardShortcut = Space
                        , color = palette.primary
                        }
                        (UI.viewButton.customSize <| ViewportSize.minDimension viewportSize // 20)
                    ]

        TypeOfWrongPage testCase ->
            let
                noMovesCube =
                    model.expectedCube |> Cube.applyAlgorithm (Algorithm.inverse <| toAlg testCase)

                nearlyThereCube =
                    model.expectedCube

                cubeSize =
                    ViewportSize.minDimension viewportSize // 5

                buttonSize =
                    ViewportSize.minDimension viewportSize // 20

                fontSize =
                    ViewportSize.minDimension viewportSize // 20

                headerSize =
                    fontSize * 4 // 3

                elementSeparation =
                    ViewportSize.minDimension viewportSize // 25
            in
            Element.map TypeOfWrongMessage <|
                column
                    [ testid "type-of-wrong-container"
                    , width fill
                    , centerY
                    , UI.paddingAll.large
                    , spacing elementSeparation
                    , Font.size fontSize
                    ]
                    [ paragraph [ centerX, Font.center, Font.bold, Font.size headerSize ] [ text "Choose the case that fits your cube state:" ]
                    , paragraph [ testid "no-move-explanation", centerX, Font.center ] [ text "1. I didn't apply any moves to the cube" ]
                    , row [ centerX ]
                        [ ViewCube.uFRWithLetters
                            [ htmlTestid "no-move-cube-state-front" ]
                            cubeSize
                            noMovesCube
                        , ViewCube.uBLWithLetters
                            [ htmlTestid "no-move-cube-state-back" ]
                            cubeSize
                            noMovesCube
                        ]
                    , buttonWithShortcut
                        hardwareAvailable
                        [ testid "no-move-button", centerX ]
                        { onPress = Just NoMoveWasApplied, color = palette.primary, labelText = "No Moves Applied", keyboardShortcut = One }
                        (UI.viewButton.customSize buttonSize)
                    , paragraph [ testid "nearly-there-explanation", centerX, Font.center ]
                        [ text "2. I can get to the expected state. I for example just got the AUF wrong"
                        ]
                    , row [ centerX ]
                        [ ViewCube.uFRWithLetters
                            [ htmlTestid "nearly-there-cube-state-front" ]
                            cubeSize
                            nearlyThereCube
                        , ViewCube.uBLWithLetters
                            [ htmlTestid "nearly-there-cube-state-back" ]
                            cubeSize
                            nearlyThereCube
                        ]
                    , buttonWithShortcut
                        hardwareAvailable
                        [ testid "nearly-there-button", centerX ]
                        { onPress = Just ExpectedStateWasReached, color = palette.primary, labelText = "Cube Is As Expected", keyboardShortcut = Two }
                        (UI.viewButton.customSize buttonSize)
                    , paragraph [ testid "unrecoverable-explanation", centerX, Font.center ]
                        [ text "3. I can't get to either of the above states, so I will just solve it to reset it" ]
                    , buttonWithShortcut
                        hardwareAvailable
                        [ testid "unrecoverable-button", centerX ]
                        { onPress = Just CubeStateIsUnrecoverable
                        , color = palette.primary
                        , labelText = "Reset To Solved"
                        , keyboardShortcut = Three
                        }
                        (UI.viewButton.customSize buttonSize)
                    ]

        WrongPage (( _, pll, _ ) as testCase) ->
            let
                testCaseCube =
                    Cube.applyAlgorithm
                        (Algorithm.inverse <| toAlg testCase)
                        Cube.solved
            in
            Element.map BetweenTestsMessage <|
                column
                    [ testid "wrong-container"
                    , centerX
                    , centerY
                    , spacing (ViewportSize.minDimension viewportSize // 20)
                    ]
                    [ el
                        [ centerX
                        , Font.size (ViewportSize.minDimension viewportSize // 20)
                        , testid "test-case-name"
                        ]
                      <|
                        text ("The Correct Answer Was " ++ pllToString pll ++ ":")
                    , row
                        [ centerX
                        ]
                        [ ViewCube.uFRWithLetters [ htmlTestid "test-case-front" ]
                            (ViewportSize.minDimension viewportSize // 4)
                            testCaseCube
                        , ViewCube.uBLWithLetters [ htmlTestid "test-case-back" ]
                            (ViewportSize.minDimension viewportSize // 4)
                            testCaseCube
                        ]
                    , paragraph
                        [ centerX
                        , Font.center
                        , Font.size (ViewportSize.minDimension viewportSize // 20)
                        , testid "expected-cube-state-text"
                        ]
                        [ text "Your Cube Should Now Look Like This:" ]
                    , row
                        [ centerX
                        ]
                        [ ViewCube.uFRWithLetters [ htmlTestid "expected-cube-state-front" ] (ViewportSize.minDimension viewportSize // 4) model.expectedCube
                        , ViewCube.uBLWithLetters [ htmlTestid "expected-cube-state-back" ] (ViewportSize.minDimension viewportSize // 4) model.expectedCube
                        ]
                    , buttonWithShortcut
                        hardwareAvailable
                        [ testid "next-button"
                        , centerX
                        ]
                        { onPress = Just StartTestGetReady
                        , labelText = "Next"
                        , keyboardShortcut = Space
                        , color = palette.primary
                        }
                        (UI.viewButton.customSize <| ViewportSize.minDimension viewportSize // 20)
                    ]


pllToString : PLL -> String
pllToString pll =
    PLL.getLetters pll ++ "-perm"


buttonWithShortcut : Shared.HardwareAvailable -> List (Attribute msg) -> { onPress : Maybe msg, labelText : String, color : Color, keyboardShortcut : Key } -> UI.Button msg -> Element msg
buttonWithShortcut hardwareAvailable attributes { onPress, labelText, keyboardShortcut, color } button =
    let
        keyString =
            case keyboardShortcut of
                W ->
                    "W"

                Space ->
                    "Space"

                One ->
                    "1"

                Two ->
                    "2"

                Three ->
                    "3"

                SomeKey keyStr ->
                    keyStr

        shortcutText =
            text <| "(" ++ keyString ++ ")"

        withShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        column [ centerX ]
                            [ el [ centerX, Font.size fontSize ] <| text labelText
                            , el [ centerX, Font.size (fontSize // 2) ] shortcutText
                            ]
                }

        withoutShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        el [ centerX, Font.size fontSize ] <| text labelText
                }
    in
    if hardwareAvailable.keyboard then
        withShortcutLabel

    else
        withoutShortcutLabel


overlayFeedbackButton : ViewportSize -> Attribute msg
overlayFeedbackButton viewportSize =
    inFront <|
        el
            [ alignBottom
            , alignRight
            , padding (ViewportSize.minDimension viewportSize // 30)
            ]
        <|
            newTabLink
                [ testid "feedback-button"
                , Background.color (rgb255 208 211 207)
                , padding (ViewportSize.minDimension viewportSize // 45)
                , Border.rounded (ViewportSize.minDimension viewportSize // 30)
                , Border.width (ViewportSize.minDimension viewportSize // 250)
                , Border.color (rgb255 0 0 0)
                , Font.size (ViewportSize.minDimension viewportSize // 25)
                ]
                { url = "https://forms.gle/ftCX7eoT71g8f5ob6", label = text "Give Feedback" }
