module Main exposing (main)

import AlgorithmRepository
import Browser
import Browser.Events as Events
import Components.Cube
import Element exposing (..)
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


view : Model -> Html.Html msg
view model =
    Html.div [] [ Components.Cube.injectStyles, layout [ padding 10 ] <| viewState model ]


viewState : Model -> Element msg
viewState model =
    case model.trainerState of
        BetweenTests message ->
            column [ testid "between-tests-container" ] [ text "Between Tests", viewEvaluationMessage message ]

        TestRunning _ elapsedTime algTested ->
            column [ testid "test-running-container" ] [ text "Test Running", displayTestCase algTested, el [ testid "timer" ] <| text <| TimeInterval.displayOneDecimal elapsedTime ]

        EvaluatingResult { result } ->
            column [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result, displayExpectedCubeState model.expectedCube ]


displayTestCase : Algorithm.Algorithm -> Element msg
displayTestCase algTested =
    el [ testid "test-case" ] <| Components.Cube.view (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse <| algTested))


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
        [ el [ testid "expected-cube-front" ] <| Components.Cube.view expectedCube
        , el [ testid "expected-cube-back" ] <| (Components.Cube.view << Cube.flip) expectedCube
        ]


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs
