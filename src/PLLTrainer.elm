module PLLTrainer exposing (..)

import Algorithm
import Browser
import Browser.Events as Events
import Cube
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Html.Events
import Json.Decode as Decode
import List.Nonempty
import PLL
import Ports
import Process
import Random
import Task
import Time
import UI
import Utils.Css exposing (testid)
import Utils.TimeInterval as TimeInterval
import ViewCube
import WebResource


init : Model
init =
    { trainerState = StartPage
    , expectedCube = Cube.solved
    }


type alias Model =
    { trainerState : TrainerState
    , expectedCube : Cube.Cube
    }


type alias TestCase =
    ( Algorithm.Algorithm, PLL.PLL, Algorithm.Algorithm )


toAlg : TestCase -> Algorithm.Algorithm
toAlg ( preauf, pll, postauf ) =
    preauf
        |> Algorithm.append (PLL.getAlg pll)
        |> Algorithm.append postauf


type TrainerState
    = StartPage
    | GetReadyScreen
    | TestRunning Time.Posix TimeInterval.TimeInterval TestCase
    | EvaluatingResult
        { spacePressStarted : Bool
        , wPressStarted : Bool
        , tooEarlyToTransition : Bool
        , result : TimeInterval.TimeInterval
        , testCase : TestCase
        }
    | CorrectPage
    | WrongPage TestCase


type Msg
    = BetweenTestsMessage BetweenTestsMsg
    | GetReadyMessage GetReadyMsg
    | TestRunningMessage TestRunningMsg
    | EvaluateResultMessage EvaluateResultMsg


type BetweenTestsMsg
    = StartTestGetReady
    | DoNothingBetweenTests


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


type Key
    = Space
    | SomeKey String
    | W


decodeNonRepeatedKeyEvent : Decode.Decoder Key
decodeNonRepeatedKeyEvent =
    let
        fields =
            Decode.map2 Tuple.pair decodeKey decodeKeyRepeat
    in
    fields
        |> Decode.andThen
            (\( key, isRepeated ) ->
                if isRepeated == True then
                    Decode.fail "Was a repeated key press"

                else
                    Decode.succeed key
            )


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Decode.Decoder Key
decodeKey =
    Decode.map toKey (Decode.field "key" Decode.string)


decodeKeyRepeat : Decode.Decoder Bool
decodeKeyRepeat =
    Decode.field "repeat" Decode.bool


toKey : String -> Key
toKey keyString =
    case keyString of
        " " ->
            Space

        "w" ->
            W

        "W" ->
            W

        _ ->
            SomeKey keyString


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        betweenTestsSubscriptions =
            Sub.map BetweenTestsMessage <|
                Events.onKeyUp <|
                    Decode.map
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

        GetReadyScreen ->
            Sub.none

        TestRunning _ _ _ ->
            Sub.map TestRunningMessage <|
                Sub.batch
                    [ Events.onKeyDown <|
                        Decode.map
                            (always <| EndTest Nothing)
                            decodeNonRepeatedKeyEvent
                    , Events.onMouseDown <|
                        Decode.succeed <|
                            EndTest Nothing
                    , Events.onAnimationFrameDelta MillisecondsPassed
                    ]

        EvaluatingResult { tooEarlyToTransition, spacePressStarted, wPressStarted } ->
            Sub.map EvaluateResultMessage <|
                if tooEarlyToTransition then
                    Sub.none

                else
                    Sub.batch
                        [ Events.onKeyDown <|
                            Decode.map
                                (\key ->
                                    case key of
                                        Space ->
                                            SpaceStarted

                                        W ->
                                            WStarted

                                        SomeKey _ ->
                                            DoNothingEvaluateResult
                                )
                                decodeNonRepeatedKeyEvent
                        , Events.onKeyUp <|
                            Decode.map
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

                                        SomeKey _ ->
                                            DoNothingEvaluateResult
                                )
                                decodeNonRepeatedKeyEvent
                        ]


topLevelEventListeners : Model -> List (Element.Attribute Msg)
topLevelEventListeners model =
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
                        Decode.succeed <|
                            EndTest Nothing
                ]

        EvaluatingResult _ ->
            []

        CorrectPage ->
            []

        WrongPage _ ->
            []


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
                        ( { model | trainerState = WrongPage keyStates.testCase, expectedCube = Cube.solved }, Cmd.none )

                    DoNothingEvaluateResult ->
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

                        CorrectPage ->
                            "CorrectPage"

                        WrongPage _ ->
                            "WrongPage"
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


view : Model -> Browser.Document Msg
view model =
    let
        feedbackButtonIfNeeded =
            case model.trainerState of
                CorrectPage ->
                    [ overlayFeedbackButton model.viewportSize ]

                WrongPage _ ->
                    [ overlayFeedbackButton model.viewportSize ]

                StartPage ->
                    []

                GetReadyScreen ->
                    []

                TestRunning _ _ _ ->
                    []

                EvaluatingResult _ ->
                    []
    in
    { title = "Speedcubing Trainer"
    , body =
        [ layout
            (topLevelEventListeners model
                ++ inFront (viewFullScreen model)
                -- Order is important as the last one shows on top
                :: feedbackButtonIfNeeded
            )
            (viewState model)
        ]
    }


viewFullScreen : Model -> Element Msg
viewFullScreen model =
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
                        , width (fill |> maximum (model.viewportSize.width * 3 // 4))
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
                                , UI.viewWebResourceLink model.palette WebResource.PLLExplanation "PLL"
                                , text " trainer which attempts to remove both the manual scrambling to create more flow, and to make practice closer to real life by timing from "
                                , UI.viewWebResourceLink model.palette WebResource.HomeGripExplanation "home grip"
                                , text
                                    ", and including recognition and pre- and post-"
                                , UI.viewWebResourceLink model.palette WebResource.AUFExplanation "AUF"
                                , text
                                    " in timing. Many improvements including intelligently displaying your weakest cases to enhance learning are planned!"
                                ]
                            ]
                        , UI.viewDivider model.palette
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
                            ViewCube.uFRWithLetters 200 model.expectedCube
                        , buttonWithShortcut
                            model
                            [ testid "start-button"
                            , centerX
                            ]
                            { onPress = Just StartTestGetReady
                            , labelText = "Start"
                            , color = model.palette.primary
                            , keyboardShortcut = Space
                            }
                            UI.viewButton.large
                        , UI.viewDivider model.palette
                        , column
                            [ testid "instructions-text"
                            , Font.center
                            , centerX
                            , UI.spacing.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ] [ text "Instructions:" ]
                            , paragraph []
                                [ text "When you press the start button (or space) you will have a second to get your cube in "
                                , UI.viewWebResourceLink model.palette
                                    WebResource.HomeGripExplanation
                                    "home grip"
                                , text ". Then a "
                                , UI.viewWebResourceLink model.palette WebResource.PLLExplanation "PLL"
                                , text " case will show up and the timer will start. If you successfully recognize the case apply the moves to your cube that would solve the cube on screen (including pre- and post-"
                                , UI.viewWebResourceLink model.palette WebResource.AUFExplanation "AUF"
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
                        , UI.viewDivider model.palette
                        , column
                            [ testid "learning-resources"
                            , centerX
                            , UI.spacing.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Region.heading 1, Font.center ] [ text "Learning Resources:" ]
                            , UI.viewUnorderedList [ centerX ]
                                [ paragraph []
                                    [ UI.viewWebResourceLink model.palette
                                        WebResource.TwoSidedPllRecognitionGuide
                                        "Two Sided PLL Recognition Guide"
                                    ]
                                , paragraph []
                                    [ UI.viewWebResourceLink model.palette WebResource.PLLAlgorithmsResource "Fast PLL Algorithms And Finger Tricks"
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
                    , Font.size (minDimension model.viewportSize * 2 // 9)
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
                    , spacing (minDimension model.viewportSize // 10)
                    ]
                    [ el [ testid "test-case", centerX ] <|
                        ViewCube.uFRNoLetters (minDimension model.viewportSize // 2) <|
                            (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse (toAlg testCase)))
                    , el
                        [ testid "timer"
                        , centerX
                        , Font.size (minDimension model.viewportSize // 5)
                        ]
                      <|
                        text <|
                            TimeInterval.displayOneDecimal elapsedTime
                    ]

        EvaluatingResult { result, tooEarlyToTransition } ->
            Element.map EvaluateResultMessage <|
                let
                    overallPadding =
                        minDimension model.viewportSize // 20

                    cubeSize =
                        minDimension model.viewportSize // 3

                    cubeSpacing =
                        minDimension model.viewportSize // 15

                    timerSize =
                        minDimension model.viewportSize // 6

                    buttonSpacing =
                        minDimension model.viewportSize // 15

                    button =
                        \attributes ->
                            UI.viewButton.customSize (minDimension model.viewportSize // 13)
                                (attributes
                                    ++ [ Font.center
                                       , width (px <| minDimension model.viewportSize // 3)
                                       ]
                                )
                in
                column
                    [ testid "evaluate-test-result-container"
                    , centerX
                    , centerY
                    , height (fill |> maximum (minDimension model.viewportSize))
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
                        [ el [ testid "expected-cube-front" ] <|
                            ViewCube.uFRWithLetters cubeSize model.expectedCube
                        , el [ testid "expected-cube-back" ] <|
                            ViewCube.uBLWithLetters cubeSize model.expectedCube
                        ]
                    , row [ centerX, spacing buttonSpacing ]
                        [ buttonWithShortcut
                            model
                            [ testid "correct-button"
                            ]
                            { onPress =
                                if tooEarlyToTransition then
                                    Nothing

                                else
                                    Just EvaluateCorrect
                            , labelText = "Correct"
                            , color = model.palette.correct
                            , keyboardShortcut = Space
                            }
                            button
                        , buttonWithShortcut
                            model
                            [ testid "wrong-button"
                            ]
                            { onPress =
                                if tooEarlyToTransition then
                                    Nothing

                                else
                                    Just EvaluateWrong
                            , labelText = "Wrong"
                            , keyboardShortcut = W
                            , color = model.palette.wrong
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
                    , spacing (minDimension model.viewportSize // 20)
                    ]
                    [ el
                        [ centerX
                        , Font.size (minDimension model.viewportSize // 20)
                        ]
                      <|
                        text "Correct!"
                    , el
                        [ centerX
                        , Font.size (minDimension model.viewportSize // 20)
                        ]
                      <|
                        text "Continue When Ready"
                    , buttonWithShortcut
                        model
                        [ testid "next-button"
                        , centerX
                        ]
                        { onPress = Just StartTestGetReady
                        , labelText = "Next"
                        , keyboardShortcut = Space
                        , color = model.palette.primary
                        }
                        (UI.viewButton.customSize <| minDimension model.viewportSize // 20)
                    ]

        WrongPage (( _, pll, _ ) as testCase) ->
            let
                testCaseCube =
                    Cube.applyAlgorithm
                        (Algorithm.inverse <| toAlg testCase)
                        model.expectedCube
            in
            Element.map BetweenTestsMessage <|
                column
                    [ testid "wrong-container"
                    , centerX
                    , centerY
                    , spacing (minDimension model.viewportSize // 20)
                    ]
                    [ el
                        [ centerX
                        , Font.size (minDimension model.viewportSize // 20)
                        , testid "test-case-name"
                        ]
                      <|
                        text ("The Correct Answer Was " ++ pllToString pll)
                    , row
                        [ testid "full-test-case"
                        , centerX
                        ]
                        [ ViewCube.uFRWithLetters
                            (minDimension model.viewportSize // 4)
                            testCaseCube
                        , ViewCube.uBLWithLetters
                            (minDimension model.viewportSize // 4)
                            testCaseCube
                        ]
                    , paragraph
                        [ centerX
                        , Font.center
                        , Font.size (minDimension model.viewportSize // 20)
                        , testid "cube-start-explanation"
                        ]
                        [ text "Solve Cube And Orient Like This Before Restarting:" ]
                    , el
                        [ testid "cube-start-state"
                        , centerX
                        ]
                      <|
                        ViewCube.uFRWithLetters (minDimension model.viewportSize // 4) model.expectedCube
                    , buttonWithShortcut
                        model
                        [ testid "next-button"
                        , centerX
                        ]
                        { onPress = Just StartTestGetReady
                        , labelText = "Next"
                        , keyboardShortcut = Space
                        , color = model.palette.primary
                        }
                        (UI.viewButton.customSize <| minDimension model.viewportSize // 20)
                    ]


viewState : Model -> Element msg
viewState _ =
    none


generateTestCase : Random.Generator TestCase
generateTestCase =
    Random.map3 (\a b c -> ( a, b, c ))
        (List.Nonempty.sample Algorithm.aufs)
        (List.Nonempty.sample PLL.allPlls)
        (List.Nonempty.sample Algorithm.aufs)


minDimension : ViewportSize -> Int
minDimension { width, height } =
    min width height


pllToString : PLL.PLL -> String
pllToString pll =
    PLL.getLetters pll ++ "-perm"


buttonWithShortcut : { a | userHasKeyboard : Bool } -> List (Attribute msg) -> { onPress : Maybe msg, labelText : String, color : Color, keyboardShortcut : Key } -> UI.Button msg -> Element msg
buttonWithShortcut { userHasKeyboard } attributes { onPress, labelText, keyboardShortcut, color } button =
    let
        keyString =
            case keyboardShortcut of
                W ->
                    "W"

                Space ->
                    "Space"

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
    if userHasKeyboard then
        withShortcutLabel

    else
        withoutShortcutLabel


overlayFeedbackButton : ViewportSize -> Attribute msg
overlayFeedbackButton viewportSize =
    inFront <|
        el
            [ alignBottom
            , alignRight
            , padding (minDimension viewportSize // 30)
            ]
        <|
            newTabLink
                [ testid "feedback-button"
                , Background.color (rgb255 208 211 207)
                , padding (minDimension viewportSize // 45)
                , Border.rounded (minDimension viewportSize // 30)
                , Border.width (minDimension viewportSize // 250)
                , Border.color (rgb255 0 0 0)
                , Font.size (minDimension viewportSize // 25)
                ]
                { url = "https://forms.gle/ftCX7eoT71g8f5ob6", label = text "Give Feedback" }