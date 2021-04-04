port module Main exposing (main)

import AlgorithmRepository
import Browser
import Browser.Events as Events
import Components.Cube
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Json.Decode as Decode
import Models.Algorithm as Algorithm
import Models.Cube as Cube
import Process
import Random
import Task
import Time
import Utils.Css exposing (testid)
import Utils.NonEmptyList as NonEmptyList
import Utils.TimeInterval as TimeInterval


main : Program ViewportSize Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


port logError : String -> Cmd msg


port onTouchStart : (Decode.Value -> msg) -> Sub msg


init : ViewportSize -> ( Model, Cmd Msg )
init viewportSize =
    ( { trainerState = StartPage
      , expectedCube = Cube.solved
      , viewportSize = viewportSize
      }
    , Cmd.none
    )


type alias ViewportSize =
    { width : Int
    , height : Int
    }


type alias Model =
    { trainerState : TrainerState
    , expectedCube : Cube.Cube
    , viewportSize : { width : Int, height : Int }
    }


type TrainerState
    = StartPage
    | TestRunning Time.Posix TimeInterval.TimeInterval Algorithm.Algorithm
    | EvaluatingResult
        { spacePressStarted : Bool
        , wPressStarted : Bool
        , ignoringKeyPressesAfterTransition : Bool
        , result : TimeInterval.TimeInterval
        }
    | CorrectPage


type Msg
    = GlobalMessage GlobalMsg
    | BetweenTestsMessage BetweenTestsMsg
    | TestRunningMessage TestRunningMsg
    | EvaluateResultMessage EvaluateResultMsg


type GlobalMsg
    = WindowResized Int Int


type BetweenTestsMsg
    = StartTest TestStartData
    | DoNothingBetweenTests


type TestStartData
    = NothingGenerated
    | AlgGenerated Algorithm.Algorithm
    | EverythingGenerated Algorithm.Algorithm Time.Posix


type TestRunningMsg
    = MillisecondsPassed Float
    | EndTest (Maybe Time.Posix)


type EvaluateResultMsg
    = EndIgnoringKeyPressesAfterTransition
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
                                StartTest NothingGenerated

                            else
                                DoNothingBetweenTests
                        )
                        decodeNonRepeatedKeyEvent

        trainerSubscriptions =
            case model.trainerState of
                StartPage ->
                    betweenTestsSubscriptions

                CorrectPage ->
                    betweenTestsSubscriptions

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
                            , onTouchStart (always (EndTest Nothing))
                            , Events.onAnimationFrameDelta MillisecondsPassed
                            ]

                EvaluatingResult { ignoringKeyPressesAfterTransition, spacePressStarted, wPressStarted } ->
                    Sub.map EvaluateResultMessage <|
                        if ignoringKeyPressesAfterTransition then
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

        globalSubscriptions =
            Events.onResize (\a b -> GlobalMessage (WindowResized a b))
    in
    Sub.batch [ trainerSubscriptions, globalSubscriptions ]


update : Msg -> Model -> ( Model, Cmd Msg )
update messageCategory model =
    case ( messageCategory, model.trainerState ) of
        ( GlobalMessage (WindowResized width height), _ ) ->
            ( { model | viewportSize = { width = width, height = height } }, Cmd.none )

        ( BetweenTestsMessage msg, StartPage ) ->
            updateBetweenTests model msg

        ( BetweenTestsMessage msg, CorrectPage ) ->
            updateBetweenTests model msg

        ( TestRunningMessage msg, TestRunning startTime intervalElapsed alg ) ->
            case msg of
                EndTest Nothing ->
                    ( model, Task.perform (\time -> TestRunningMessage <| EndTest (Just time)) Time.now )

                EndTest (Just endTime) ->
                    ( { model
                        | trainerState =
                            EvaluatingResult
                                { spacePressStarted = False
                                , wPressStarted = False
                                , ignoringKeyPressesAfterTransition = True
                                , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                                }
                        , expectedCube = model.expectedCube |> Cube.applyAlgorithm alg
                      }
                    , Task.perform (always <| EvaluateResultMessage EndIgnoringKeyPressesAfterTransition) (Process.sleep 100)
                    )

                MillisecondsPassed timeDelta ->
                    ( { model | trainerState = TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed) alg }, Cmd.none )

        ( EvaluateResultMessage msg, EvaluatingResult keyStates ) ->
            Tuple.mapSecond (Cmd.map EvaluateResultMessage) <|
                case msg of
                    EndIgnoringKeyPressesAfterTransition ->
                        ( { model | trainerState = EvaluatingResult { keyStates | ignoringKeyPressesAfterTransition = False } }, Cmd.none )

                    SpaceStarted ->
                        ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                    WStarted ->
                        ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                    EvaluateCorrect ->
                        ( { model | trainerState = CorrectPage }, Cmd.none )

                    EvaluateWrong ->
                        ( { model | trainerState = StartPage, expectedCube = Cube.solved }, Cmd.none )

                    DoNothingEvaluateResult ->
                        ( model, Cmd.none )

        ( msg, trainerState ) ->
            ( model
            , let
                msgString =
                    case msg of
                        GlobalMessage _ ->
                            "GlobalMessage"

                        BetweenTestsMessage _ ->
                            "BetweenTestsMessage"

                        TestRunningMessage _ ->
                            "TestRunningMessage"

                        EvaluateResultMessage _ ->
                            "EvaluateResultMessage"

                trainerStateString =
                    case trainerState of
                        StartPage ->
                            "StartPage"

                        TestRunning _ _ _ ->
                            "TestRunning"

                        EvaluatingResult _ ->
                            "EvaluatingResult"

                        CorrectPage ->
                            "CorrectPage"
              in
              logError
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
    Tuple.mapSecond (Cmd.map BetweenTestsMessage) <|
        case msg of
            StartTest NothingGenerated ->
                ( model, Random.generate (\alg -> StartTest (AlgGenerated alg)) generatePll )

            StartTest (AlgGenerated alg) ->
                ( model, Task.perform (\time -> StartTest (EverythingGenerated alg time)) Time.now )

            StartTest (EverythingGenerated alg startTime) ->
                ( { model | trainerState = TestRunning startTime TimeInterval.zero alg }, Cmd.none )

            DoNothingBetweenTests ->
                ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    Html.div [] [ Components.Cube.injectStyles, layout [ padding 10, inFront <| viewFullScreen model ] <| viewState model ]


viewFullScreen : Model -> Element Msg
viewFullScreen model =
    case model.trainerState of
        StartPage ->
            Element.map BetweenTestsMessage <|
                column
                    [ testid "start-page-container"
                    , centerX
                    , centerY
                    , spacing (minDimension model.viewportSize // 20)
                    ]
                    [ el
                        [ Font.center
                        , Font.size (minDimension model.viewportSize // 20)
                        , testid "cube-start-explanation"
                        ]
                      <|
                        text "Orient Solved Cube Like This:"
                    , el
                        [ testid "cube-start-state"
                        , centerX
                        ]
                      <|
                        Components.Cube.view (minDimension model.viewportSize // 4) Cube.solved
                    , Input.button
                        [ testid "start-button"
                        , centerX
                        , Background.color <| rgb255 0 128 0
                        , padding (minDimension model.viewportSize // 40)
                        , Border.rounded (minDimension model.viewportSize // 45)
                        , Font.size (minDimension model.viewportSize // 25)
                        ]
                        { onPress = Just <| StartTest NothingGenerated
                        , label = text "Start"
                        }
                    ]

        TestRunning _ elapsedTime algTested ->
            Element.map TestRunningMessage <|
                column
                    [ testid "test-running-container"
                    , centerX
                    , centerY
                    , spacing (minDimension model.viewportSize // 10)
                    ]
                    [ el [ testid "test-case", centerX ] <|
                        Components.Cube.view (minDimension model.viewportSize // 2) <|
                            (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse algTested))
                    , el
                        [ testid "timer"
                        , centerX
                        , Font.size (min model.viewportSize.height model.viewportSize.width // 5)
                        ]
                      <|
                        text <|
                            TimeInterval.displayOneDecimal elapsedTime
                    ]

        EvaluatingResult { result } ->
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

                    buttonSize =
                        minDimension model.viewportSize // 15

                    buttonPadding =
                        buttonSize * 2 // 3

                    buttonRounding =
                        buttonSize // 3

                    buttonSpacing =
                        buttonSize
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
                            Components.Cube.view cubeSize model.expectedCube
                        , el [ testid "expected-cube-back" ] <|
                            (model.expectedCube
                                |> Cube.applyAlgorithm (Algorithm.build [ Algorithm.Turn Algorithm.Y Algorithm.Halfway Algorithm.Clockwise ])
                                |> Components.Cube.view cubeSize
                            )
                        ]
                    , row [ centerX, spacing buttonSpacing ]
                        [ Input.button
                            [ testid "correct-button"
                            , Background.color <| rgb255 0 128 0
                            , padding buttonPadding
                            , Border.rounded buttonRounding
                            , Font.size buttonSize
                            , Font.center
                            , width (px <| minDimension model.viewportSize // 3)
                            ]
                            { onPress = Just EvaluateCorrect, label = text "Correct" }
                        , Input.button
                            [ testid "wrong-button"
                            , Background.color <| rgb255 255 0 0
                            , padding buttonPadding
                            , Border.rounded buttonRounding
                            , Font.size buttonSize
                            , Font.center
                            , width (px <| minDimension model.viewportSize // 3)
                            ]
                            { onPress = Just EvaluateWrong, label = text "Wrong" }
                        ]
                    ]

        CorrectPage ->
            Element.map BetweenTestsMessage <|
                column
                    [ testid "correct-container"
                    , centerX
                    , centerY
                    ]
                    [ Input.button
                        [ testid "next-button"
                        , centerX
                        , Background.color <| rgb255 0 128 0
                        , padding (minDimension model.viewportSize // 40)
                        , Border.rounded (minDimension model.viewportSize // 45)
                        , Font.size (minDimension model.viewportSize // 25)
                        ]
                        { onPress = Just <| StartTest NothingGenerated
                        , label = text "Next"
                        }
                    ]


viewState : Model -> Element msg
viewState _ =
    none


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs


minDimension : ViewportSize -> Int
minDimension { width, height } =
    min width height
