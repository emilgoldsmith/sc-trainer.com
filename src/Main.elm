module Main exposing (main)

import AlgorithmRepository
import Browser
import Browser.Events as Events
import Components.Cube
import Html exposing (..)
import Html.Attributes exposing (..)
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


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { trainerState = BetweenTests NoEvaluationMessage, expectedCube = Cube.solved }, Cmd.none )


type alias Model =
    { trainerState : TrainerState
    , expectedCube : Cube.Cube
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
    | AlgToTestGenerated Algorithm.Algorithm
    | StartTest Algorithm.Algorithm Time.Posix
    | MillisecondsPassed Float
    | EndTest Time.Posix
    | EndIgnoringKeyPressesAfterTransition


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
    case model.trainerState of
        BetweenTests _ ->
            Events.onKeyUp <| Decode.map (withIgnoreIfIsRepeated KeyUp) decodeKeyEvent

        TestRunning _ _ _ ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map (withIgnoreIfIsRepeated KeyDown)
                        decodeKeyEvent
                , Events.onMouseDown <|
                    Decode.succeed <|
                        KeyDown (SomeKey "mouseDown")
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


withIgnoreIfIsRepeated : (Key -> Msg) -> KeyEvent -> Msg
withIgnoreIfIsRepeated message (KeyEvent key isRepeated) =
    if isRepeated then
        IgnoredKeyEvent

    else
        message key


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.trainerState of
        BetweenTests _ ->
            case msg of
                KeyUp Space ->
                    ( model, Random.generate AlgToTestGenerated generatePll )

                AlgToTestGenerated alg ->
                    ( model, Task.perform (StartTest alg) Time.now )

                StartTest alg startTime ->
                    ( { model | trainerState = TestRunning startTime TimeInterval.zero alg }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TestRunning startTime intervalElapsed alg ->
            case msg of
                KeyDown _ ->
                    ( model, Task.perform EndTest Time.now )

                EndTest endTime ->
                    ( { model
                        | trainerState =
                            EvaluatingResult
                                { spacePressStarted = False
                                , wPressStarted = False
                                , ignoringKeyPressesAfterTransition = True
                                , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                                }
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


view : Model -> Html msg
view model =
    div [] [ Components.Cube.injectStyles, viewState model ]


viewState : Model -> Html msg
viewState model =
    case model.trainerState of
        BetweenTests message ->
            div [ testid "between-tests-container" ] [ text "Between Tests", viewEvaluationMessage message ]

        TestRunning _ elapsedTime algTested ->
            div [ testid "test-running-container" ] [ text "Test Running", displayTestCase algTested, div [ testid "timer" ] [ text <| TimeInterval.displayOneDecimal elapsedTime ] ]

        EvaluatingResult { result } ->
            div [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result, displayExpectedCubeState model.expectedCube ]


displayTestCase : Algorithm.Algorithm -> Html msg
displayTestCase algTested =
    div [ testid "test-case" ] [ Components.Cube.view (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse <| algTested)) ]


displayTimeResult : TimeInterval.TimeInterval -> Html msg
displayTimeResult result =
    div [ testid "time-result" ] [ text <| TimeInterval.displayTwoDecimals result ]


viewEvaluationMessage : EvaluationMessage -> Html msg
viewEvaluationMessage message =
    case message of
        NoEvaluationMessage ->
            div [] [ text "Auto-deploy works!" ]

        CorrectEvaluation ->
            div [ testid "correct-evaluation-message" ] [ text "Correct" ]

        WrongEvaluation ->
            div [ testid "wrong-evaluation-message" ] [ text "Wrong" ]


displayExpectedCubeState : Cube.Cube -> Html msg
displayExpectedCubeState expectedCube =
    div []
        [ div [ testid "expected-cube-front" ] [ Components.Cube.view expectedCube ]
        , div [ testid "expected-cube-back" ] [ Components.Cube.view expectedCube ]
        ]


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs
