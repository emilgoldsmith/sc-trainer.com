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
    ( { trainerState = BetweenTests NoEvaluationMessage }, Cmd.none )


type alias Model =
    { trainerState : TrainerState
    }


type TrainerState
    = BetweenTests EvaluationMessage
    | TestRunning Time.Posix TimeInterval.Type Algorithm.Algorithm
    | EvaluatingResult { spacePressStarted : Bool, wPressStarted : Bool, keysHeldDownFromTest : List Key, inTransition : Bool, result : TimeInterval.Type, algorithmTested : Algorithm.Algorithm }


allPressed : { a | spacePressStarted : Bool, wPressStarted : Bool } -> Bool
allPressed { spacePressStarted, wPressStarted } =
    spacePressStarted && wPressStarted


type EvaluationMessage
    = NoEvaluationMessage
    | CorrectEvaluation
    | WrongEvaluation


type Msg
    = KeyUp KeyEvent
    | KeyDown KeyEvent
    | AlgToTestGenerated Algorithm.Algorithm
    | StartTest Algorithm.Algorithm Time.Posix
    | MillisecondsPassed Float
    | EndTest Key Time.Posix
    | EndTransition


type alias MillisecondsSinceDocumentCreation =
    Float


type KeyEvent
    = KeyEvent Key MillisecondsSinceDocumentCreation


type Key
    = Space
    | SomeKey String
    | W


decodeKeyEvent : Decode.Decoder KeyEvent
decodeKeyEvent =
    Decode.map2 KeyEvent decodeKey decodeEventTimestamp


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Decode.Decoder Key
decodeKey =
    Decode.map toKey (Decode.field "key" Decode.string)


decodeEventTimestamp : Decode.Decoder MillisecondsSinceDocumentCreation
decodeEventTimestamp =
    Decode.field "timeStamp" Decode.float


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
            Events.onKeyUp <| Decode.map KeyUp decodeKeyEvent

        TestRunning _ _ _ ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map KeyDown
                        decodeKeyEvent
                , Events.onMouseDown <|
                    Decode.map KeyDown <|
                        Decode.map (KeyEvent <| SomeKey "mouseDown") decodeEventTimestamp
                , Events.onAnimationFrameDelta MillisecondsPassed
                ]

        EvaluatingResult keyStates ->
            Sub.batch
                [ if allPressed keyStates then
                    Sub.none

                  else
                    Events.onKeyDown <| Decode.map KeyDown decodeKeyEvent
                , Events.onKeyUp <| Decode.map KeyUp decodeKeyEvent
                ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.trainerState of
        BetweenTests _ ->
            case msg of
                KeyUp (KeyEvent Space timestamp) ->
                    ( model, Random.generate AlgToTestGenerated generatePll )

                AlgToTestGenerated alg ->
                    ( model, Task.perform (StartTest alg) Time.now )

                StartTest alg startTime ->
                    ( { model | trainerState = TestRunning startTime TimeInterval.zero alg }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TestRunning startTime intervalElapsed alg ->
            case msg of
                KeyDown (KeyEvent key _) ->
                    ( model, Task.perform (EndTest key) Time.now )

                EndTest key endTime ->
                    ( { model
                        | trainerState =
                            EvaluatingResult
                                { spacePressStarted = False
                                , wPressStarted = False
                                , keysHeldDownFromTest = [ key ]
                                , inTransition = True
                                , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                                , algorithmTested = alg
                                }
                      }
                    , Task.perform (always EndTransition) (Process.sleep 100)
                    )

                MillisecondsPassed timeDelta ->
                    ( { model | trainerState = TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed) alg }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EvaluatingResult ({ spacePressStarted, wPressStarted, keysHeldDownFromTest, inTransition } as keyStates) ->
            if inTransition then
                case msg of
                    KeyDown (KeyEvent key _) ->
                        if List.member key keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( { model | trainerState = EvaluatingResult { keyStates | keysHeldDownFromTest = List.append keysHeldDownFromTest [ key ] } }, Cmd.none )

                    KeyUp (KeyEvent key _) ->
                        ( { model | trainerState = EvaluatingResult { keyStates | keysHeldDownFromTest = List.filter ((/=) key) keysHeldDownFromTest } }, Cmd.none )

                    EndTransition ->
                        ( { model | trainerState = EvaluatingResult { keyStates | inTransition = False } }, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

            else
                case msg of
                    KeyDown (KeyEvent Space _) ->
                        if List.member Space keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                    KeyDown (KeyEvent W _) ->
                        if List.member W keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                    KeyUp (KeyEvent key _) ->
                        if List.member key keysHeldDownFromTest then
                            ( { model | trainerState = EvaluatingResult { keyStates | keysHeldDownFromTest = [] } }, Cmd.none )

                        else
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
            div [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result ]


displayTestCase : Algorithm.Algorithm -> Html msg
displayTestCase algTested =
    div [ testid "test-case" ] [ Components.Cube.view (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse <| algTested)) ]


displayTimeResult : TimeInterval.Type -> Html msg
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


generatePll : Random.Generator Algorithm.Algorithm
generatePll =
    let
        (NonEmptyList.NonEmptyList x xs) =
            NonEmptyList.concatMap Algorithm.withAllAufCombinations AlgorithmRepository.pllList
    in
    Random.uniform x xs
