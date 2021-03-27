module Main exposing (main)

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


allPressed : { a | spacePressStarted : Bool, wPressStarted : Bool } -> Bool
allPressed { spacePressStarted, wPressStarted } =
    spacePressStarted && wPressStarted


type EvaluationMessage
    = NoEvaluationMessage
    | CorrectEvaluation
    | WrongEvaluation


type Msg
    = KeyUp Key
    | KeyDown Key
    | IgnoredKeyEvent
    | StartTest TestStartData
    | MillisecondsPassed Float
    | EndTest (Maybe Time.Posix)
    | EndIgnoringKeyPressesAfterTransition
    | WindowResized Int Int


type TestStartData
    = NothingGenerated
    | AlgGenerated Algorithm.Algorithm
    | EverythingGenerated Algorithm.Algorithm Time.Posix


type alias IsRepeatedKeyPressFlag =
    Bool


type KeyEvent
    = KeyEvent Key IsRepeatedKeyPressFlag


type Key
    = Space
    | SomeKey String
    | W


decodeKeyEvent : Decode.Decoder KeyEvent
decodeKeyEvent =
    Decode.map2 KeyEvent decodeKey decodeKeyRepeat


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Decode.Decoder Key
decodeKey =
    Decode.map toKey (Decode.field "key" Decode.string)


decodeKeyRepeat : Decode.Decoder IsRepeatedKeyPressFlag
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
                    Events.onKeyUp <|
                        Decode.map
                            (\(KeyEvent key isRepeated) ->
                                if key == Space && isRepeated == False then
                                    StartTest NothingGenerated

                                else
                                    IgnoredKeyEvent
                            )
                            decodeKeyEvent

                TestRunning _ _ _ ->
                    Sub.batch
                        [ Events.onKeyDown <|
                            Decode.map
                                (\(KeyEvent _ isRepeated) ->
                                    if isRepeated == False then
                                        EndTest Nothing

                                    else
                                        IgnoredKeyEvent
                                )
                                decodeKeyEvent
                        , Events.onMouseDown <|
                            Decode.succeed <|
                                EndTest Nothing
                        , Events.onAnimationFrameDelta MillisecondsPassed
                        ]

                EvaluatingResult keyStates ->
                    if keyStates.ignoringKeyPressesAfterTransition then
                        Sub.none

                    else
                        Sub.batch
                            [ if allPressed keyStates then
                                Sub.none

                              else
                                Events.onKeyDown <| Decode.map (withIgnoreIfIsRepeated KeyDown) decodeKeyEvent
                            , Events.onKeyUp <| Decode.map (withIgnoreIfIsRepeated KeyUp) decodeKeyEvent
                            ]

        globalSubscriptions =
            Events.onResize WindowResized
    in
    Sub.batch [ trainerSubscriptions, globalSubscriptions ]


withIgnoreIfIsRepeated : (Key -> Msg) -> KeyEvent -> Msg
withIgnoreIfIsRepeated message (KeyEvent key isRepeated) =
    if isRepeated then
        IgnoredKeyEvent

    else
        message key


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WindowResized width height ->
            ( { model | viewportSize = { width = width, height = height } }, Cmd.none )

        _ ->
            case model.trainerState of
                BetweenTests _ ->
                    case msg of
                        StartTest NothingGenerated ->
                            ( model, Random.generate (\alg -> StartTest (AlgGenerated alg)) generatePll )

                        StartTest (AlgGenerated alg) ->
                            ( model, Task.perform (\time -> StartTest (EverythingGenerated alg time)) Time.now )

                        StartTest (EverythingGenerated alg startTime) ->
                            ( { model | trainerState = TestRunning startTime TimeInterval.zero alg }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                TestRunning startTime intervalElapsed alg ->
                    case msg of
                        EndTest Nothing ->
                            ( model, Task.perform (\time -> EndTest (Just time)) Time.now )

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
                            , Task.perform (always EndIgnoringKeyPressesAfterTransition) (Process.sleep 100)
                            )

                        MillisecondsPassed timeDelta ->
                            ( { model | trainerState = TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed) alg }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                EvaluatingResult ({ spacePressStarted, wPressStarted } as keyStates) ->
                    case msg of
                        EndIgnoringKeyPressesAfterTransition ->
                            ( { model | trainerState = EvaluatingResult { keyStates | ignoringKeyPressesAfterTransition = False } }, Cmd.none )

                        KeyDown Space ->
                            ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                        KeyDown W ->
                            ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                        KeyUp key ->
                            case key of
                                Space ->
                                    if spacePressStarted then
                                        ( { model | trainerState = BetweenTests CorrectEvaluation }, Cmd.none )

                                    else
                                        ( model, Cmd.none )

                                W ->
                                    if wPressStarted then
                                        ( { model | trainerState = BetweenTests WrongEvaluation }, Cmd.none )

                                    else
                                        ( model, Cmd.none )

                                _ ->
                                    ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )


view : Model -> Html.Html Msg
view model =
    Html.div [] [ Components.Cube.injectStyles, layout [ padding 10, inFront <| viewFullScreen model ] <| viewState model ]


viewFullScreen : Model -> Element Msg
viewFullScreen model =
    case model.trainerState of
        BetweenTests message ->
            el
                [ testid "between-tests-container"
                , width fill
                , height fill
                ]
            <|
                column [ centerX, centerY, spacing 50, padding 50 ]
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
            el
                [ testid "test-running-container"
                , width fill
                , height fill
                ]
            <|
                column
                    [ centerX
                    , centerY
                    , spacing 50
                    ]
                    [ el [ centerX ] <| displayTestCase model.viewportSize algTested
                    , el [ testid "timer", centerX, Font.size (min model.viewportSize.height model.viewportSize.width // 5) ] <| text <| TimeInterval.displayOneDecimal elapsedTime
                    ]

        EvaluatingResult { result } ->
            column [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result, displayExpectedCubeState model.expectedCube ]


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


displayTimeResult : TimeInterval.TimeInterval -> Element msg
displayTimeResult result =
    el [ testid "time-result" ] <| text <| TimeInterval.displayTwoDecimals result


viewEvaluationMessage : EvaluationMessage -> Element msg
viewEvaluationMessage message =
    case message of
        NoEvaluationMessage ->
            el [] <| text "Auto-deploy works!"

        CorrectEvaluation ->
            el [ testid "correct-evaluation-message" ] <| text "Correct"

        WrongEvaluation ->
            el [ testid "wrong-evaluation-message" ] <| text "Wrong"


displayExpectedCubeState : Cube.Cube -> Element msg
displayExpectedCubeState expectedCube =
    row []
        [ el [ testid "expected-cube-front" ] <| Components.Cube.view 16 expectedCube
        , el [ testid "expected-cube-back" ] <| (Components.Cube.view 16 << Cube.flip) expectedCube
        ]


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs
