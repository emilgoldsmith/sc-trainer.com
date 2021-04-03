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
import Html.Attributes
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
    ( { trainerState = BetweenTests NoEvaluationMessage
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
    = BetweenTests EvaluationMessage
    | TestRunning Time.Posix TimeInterval.TimeInterval Algorithm.Algorithm
    | EvaluatingResult
        { spacePressStarted : Bool
        , wPressStarted : Bool
        , ignoringKeyPressesAfterTransition : Bool
        , result : TimeInterval.TimeInterval
        }


type EvaluationMessage
    = NoEvaluationMessage
    | CorrectEvaluation
    | WrongEvaluation


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
        trainerSubscriptions =
            case model.trainerState of
                BetweenTests _ ->
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

        ( BetweenTestsMessage msg, BetweenTests _ ) ->
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
                        ( { model | trainerState = BetweenTests CorrectEvaluation }, Cmd.none )

                    EvaluateWrong ->
                        ( { model | trainerState = BetweenTests WrongEvaluation }, Cmd.none )

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
                        BetweenTests _ ->
                            "BetweenTests"

                        TestRunning _ _ _ ->
                            "TestRunning"

                        EvaluatingResult _ ->
                            "EvaluatingResult"
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


view : Model -> Html.Html Msg
view model =
    Html.div [] [ Components.Cube.injectStyles, layout [ padding 10, inFront <| viewFullScreen model ] <| viewState model ]


viewFullScreen : Model -> Element Msg
viewFullScreen model =
    case model.trainerState of
        BetweenTests message ->
            Element.map BetweenTestsMessage <|
                el
                    [ testid "between-tests-container"
                    , width fill
                    , height fill
                    ]
                <|
                    column
                        [ centerX
                        , centerY
                        , spacing 50
                        , padding 50
                        ]
                        [ el [ centerX ] <| text "Between Tests"
                        , el [ centerX ] <| viewEvaluationMessage message
                        , Input.button
                            [ testid "begin-button"
                            , centerX
                            , Background.color <| rgb255 0 128 0
                            , padding 25
                            , Border.rounded 15
                            ]
                            { onPress = Just <| StartTest NothingGenerated
                            , label = text "Begin"
                            }
                        ]

        TestRunning _ elapsedTime algTested ->
            Element.map TestRunningMessage <|
                el
                    [ testid "test-running-container"
                    , width fill
                    , height fill

                    -- -- This is important to avoid a delay in the user experience when they
                    -- -- end the test
                    -- , htmlAttribute <| Html.Attributes.style "touch-action" "manipulation"
                    ]
                <|
                    column
                        [ centerX
                        , centerY
                        , spacing 50
                        ]
                        [ el [ centerX ] <|
                            displayTestCase model.viewportSize algTested
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
                    minDimension =
                        min model.viewportSize.height model.viewportSize.width

                    overallPadding =
                        minDimension // 20

                    cubeSize =
                        minDimension // 3

                    timerSize =
                        minDimension // 6

                    buttonSize =
                        minDimension // 15

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
                    , height (fill |> maximum minDimension)
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
                    , row [ centerX ]
                        [ el [ testid "expected-cube-front" ] <|
                            Components.Cube.view cubeSize model.expectedCube
                        , el [ testid "expected-cube-back" ] <|
                            (model.expectedCube |> Cube.applyAlgorithm (Algorithm.build [ Algorithm.Turn Algorithm.Y Algorithm.Halfway Algorithm.Clockwise ]) |> Components.Cube.view cubeSize)
                        ]
                    , row [ centerX, spacing buttonSpacing ]
                        [ Input.button
                            [ testid "correct-button"
                            , Background.color <| rgb255 0 128 0
                            , padding buttonPadding
                            , Border.rounded buttonRounding
                            , Font.size buttonSize
                            ]
                            { onPress = Just EvaluateCorrect, label = text "Correct" }
                        , Input.button
                            [ testid "wrong-button"
                            , Background.color <| rgb255 255 0 0
                            , padding buttonPadding
                            , Border.rounded buttonRounding
                            , Font.size buttonSize
                            ]
                            { onPress = Just EvaluateWrong, label = text "Wrong" }
                        ]
                    ]


viewState : Model -> Element msg
viewState _ =
    none


displayTestCase : ViewportSize -> Algorithm.Algorithm -> Element msg
displayTestCase viewportSize algTested =
    let
        minDimension =
            min viewportSize.height viewportSize.width
    in
    el [ testid "test-case" ] <|
        Components.Cube.view (minDimension // 2) <|
            (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse algTested))


viewEvaluationMessage : EvaluationMessage -> Element msg
viewEvaluationMessage message =
    case message of
        NoEvaluationMessage ->
            el [] <| text "Auto-deploy works!"

        CorrectEvaluation ->
            el [ testid "correct-evaluation-message" ] <| text "Correct"

        WrongEvaluation ->
            el [ testid "wrong-evaluation-message" ] <| text "Wrong"


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs
