module Pages.Home_ exposing (Model, Msg, page)

import Algorithm exposing (Algorithm)
import Browser.Events
import Cube exposing (Cube)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Gen.Params.Home_ exposing (Params)
import Html.Events
import Json.Decode
import List.Nonempty
import PLL exposing (PLL)
import PLLTrainer exposing (overlayFeedbackButton)
import Page
import Ports
import Process
import Random
import Request
import Shared
import Task
import Time
import UI
import Utils.Css exposing (testid)
import Utils.TimeInterval as TimeInterval exposing (TimeInterval)
import View exposing (View)
import ViewportSize exposing (ViewportSize)


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
    | CorrectPage
    | WrongPage TestCase


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

                                        SomeKey _ ->
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

                                        SomeKey _ ->
                                            DoNothingEvaluateResult
                                )
                                decodeNonRepeatedKeyEvent
                        ]


type Key
    = Space
    | SomeKey String
    | W


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

            CorrectPage ->
                []

            WrongPage _ ->
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
    , body = View.Custom Element.none
    }


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
