module Main exposing (main)

import Browser
import Browser.Events as Events
import Components.Cube
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Models.Algorithm as Algorithm
import Models.Cube as Cube
import Process
import Task
import Time
import Utils.Css exposing (testid)
import Utils.TimeInterval as TimeInterval exposing (TimeInterval)


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
    ( BetweenTests NoEvaluationMessage, Cmd.none )


type alias Model =
    TrainerState


type TrainerState
    = BetweenTests EvaluationMessage
    | TestRunning Time.Posix TimeInterval
    | EvaluatingResult { spacePressStarted : Bool, wPressStarted : Bool, keysHeldDownFromTest : List Key, inTransition : Bool, result : TimeInterval }


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
    | NextAnimationFrame Float
    | StartTest Time.Posix
    | EndTest Key Time.Posix
    | EndTransition


type KeyEvent
    = KeyEvent Key Float


type Key
    = Space
    | SomeKey String
    | W


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Decode.Decoder Key
decodeKey =
    Decode.map toKey (Decode.field "key" Decode.string)


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
    case model of
        BetweenTests _ ->
            Events.onKeyUp <| Decode.map KeyUp decodeKey

        TestRunning _ _ ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map KeyDown
                        decodeKey
                , Events.onMouseDown <|
                    Decode.succeed
                        (KeyDown <| SomeKey "mouseDown")
                , Events.onAnimationFrameDelta NextAnimationFrame
                ]

        EvaluatingResult keyStates ->
            Sub.batch
                [ if allPressed keyStates then
                    Sub.none

                  else
                    Events.onKeyDown <| Decode.map KeyDown decodeKey
                , Events.onKeyUp <| Decode.map KeyUp decodeKey
                ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        BetweenTests _ ->
            case msg of
                KeyUp Space ->
                    ( model, Task.perform StartTest Time.now )

                StartTest startTime ->
                    ( TestRunning startTime TimeInterval.zero, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TestRunning startTime intervalElapsed ->
            case msg of
                KeyDown key ->
                    ( model, Task.perform (EndTest key) Time.now )

                EndTest keyPressed endTime ->
                    ( EvaluatingResult
                        { spacePressStarted = False
                        , wPressStarted = False
                        , keysHeldDownFromTest = [ keyPressed ]
                        , inTransition = True
                        , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                        }
                    , Task.perform (\_ -> EndTransition) (Process.sleep 100)
                    )

                NextAnimationFrame timeDelta ->
                    ( TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EvaluatingResult ({ spacePressStarted, wPressStarted, keysHeldDownFromTest, inTransition } as keyStates) ->
            if inTransition then
                case msg of
                    KeyDown key ->
                        if List.member key keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( EvaluatingResult { keyStates | keysHeldDownFromTest = List.append keysHeldDownFromTest [ key ] }, Cmd.none )

                    KeyUp key ->
                        ( EvaluatingResult { keyStates | keysHeldDownFromTest = List.filter ((/=) key) keysHeldDownFromTest }, Cmd.none )

                    EndTransition ->
                        ( EvaluatingResult { keyStates | inTransition = False }, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

            else
                case msg of
                    KeyDown Space ->
                        if List.member Space keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( EvaluatingResult { keyStates | spacePressStarted = True }, Cmd.none )

                    KeyDown W ->
                        if List.member W keysHeldDownFromTest then
                            ( model, Cmd.none )

                        else
                            ( EvaluatingResult { keyStates | wPressStarted = True }, Cmd.none )

                    KeyUp key ->
                        if List.member key keysHeldDownFromTest then
                            ( EvaluatingResult { keyStates | keysHeldDownFromTest = [] }, Cmd.none )

                        else
                            case key of
                                Space ->
                                    if spacePressStarted then
                                        ( BetweenTests CorrectEvaluation, Cmd.none )

                                    else
                                        ( model, Cmd.none )

                                W ->
                                    if wPressStarted then
                                        ( BetweenTests WrongEvaluation, Cmd.none )

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
    case model of
        BetweenTests message ->
            div [ testid "between-tests-container" ] [ text "Between Tests", viewEvaluationMessage message ]

        TestRunning _ elapsedTime ->
            div [ testid "test-running-container" ] [ text "Test Running", displayTestCase, div [ testid "timer" ] [ text <| TimeInterval.displayOneDecimal elapsedTime ] ]

        EvaluatingResult { result } ->
            div [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result ]


displayTestCase : Html msg
displayTestCase =
    div [ testid "test-case" ] [ Components.Cube.view (Cube.solved |> Cube.applyAlgorithm (Algorithm.build [ Algorithm.Turn Algorithm.M Algorithm.OneQuarter Algorithm.Clockwise ])) ]


displayTimeResult : TimeInterval -> Html msg
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
