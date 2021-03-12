module Main exposing (main)

import Browser
import Browser.Events as Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Process
import Set exposing (Set)
import Task
import Time
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
    ( { trainerState = BetweenTests NoEvaluationMessage, snackbars = [] }, Cmd.none )


type alias Model =
    { trainerState : TrainerState
    , snackbars : List String
    }


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
    | DeleteOldestSnackbar
    | NextAnimationFrame Float
    | StartTest Time.Posix
    | EndTest Key Time.Posix
    | EndTransition


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
    case model.trainerState of
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
    case msg of
        DeleteOldestSnackbar ->
            ( { model | snackbars = List.take (List.length model.snackbars - 1) model.snackbars }, Cmd.none )

        _ ->
            case model.trainerState of
                BetweenTests _ ->
                    case msg of
                        KeyUp Space ->
                            ( model, Task.perform StartTest Time.now )

                        StartTest startTime ->
                            ( { model | trainerState = TestRunning startTime TimeInterval.zero }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                TestRunning startTime intervalElapsed ->
                    case msg of
                        KeyDown key ->
                            ( model, Task.perform (EndTest key) Time.now )

                        EndTest keyPressed endTime ->
                            ( { model
                                | trainerState =
                                    EvaluatingResult
                                        { spacePressStarted = False
                                        , wPressStarted = False
                                        , keysHeldDownFromTest = [ keyPressed ]
                                        , inTransition = True
                                        , result = TimeInterval.betweenTimestamps { start = startTime, end = endTime }
                                        }
                              }
                            , Task.perform (\_ -> EndTransition) (Process.sleep 100)
                            )

                        NextAnimationFrame timeDelta ->
                            ( { model | trainerState = TestRunning startTime (TimeInterval.increment timeDelta intervalElapsed) }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                EvaluatingResult ({ spacePressStarted, wPressStarted, keysHeldDownFromTest, inTransition } as keyStates) ->
                    if inTransition then
                        case msg of
                            KeyDown key ->
                                if List.member key keysHeldDownFromTest then
                                    ( model, Cmd.none )

                                else
                                    ( { model | trainerState = EvaluatingResult { keyStates | keysHeldDownFromTest = List.append keysHeldDownFromTest [ key ] } }, Cmd.none )

                            KeyUp key ->
                                ( { model | trainerState = EvaluatingResult { keyStates | keysHeldDownFromTest = List.filter ((/=) key) keysHeldDownFromTest } }, Cmd.none )

                            EndTransition ->
                                ( { model | trainerState = EvaluatingResult { keyStates | inTransition = False } }, Cmd.none )

                            _ ->
                                ( model, Cmd.none )

                    else
                        case msg of
                            KeyDown Space ->
                                if List.member Space keysHeldDownFromTest then
                                    ( model, Cmd.none )

                                else
                                    ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                            KeyDown W ->
                                if List.member W keysHeldDownFromTest then
                                    ( model, Cmd.none )

                                else
                                    ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                            KeyUp key ->
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


addSnackbar : Model -> String -> ( Model, Cmd Msg )
addSnackbar model snackbarText =
    ( { model | snackbars = snackbarText :: model.snackbars }, Task.perform (always DeleteOldestSnackbar) (Process.sleep 3000) )


view : Model -> Html Msg
view model =
    div [] [ viewState model, viewSnackbars model ]


viewSnackbars : Model -> Html Msg
viewSnackbars model =
    div [ style "position" "fixed", style "top" "20px", style "left" "50%" ] <| List.map viewSnackbar model.snackbars


viewState : Model -> Html Msg
viewState model =
    case model.trainerState of
        BetweenTests message ->
            div [ testid "between-tests-container" ] [ text "Between Tests", viewEvaluationMessage message ]

        TestRunning _ elapsedTime ->
            div [ testid "test-running-container" ] [ text "Test Running", div [ testid "timer" ] [ text <| TimeInterval.displayOneDecimal elapsedTime ] ]

        EvaluatingResult { result } ->
            div [ testid "evaluate-test-result-container" ] [ text <| "Evaluating Result", displayTimeResult result ]


testid : String -> Attribute Msg
testid =
    attribute "data-testid"


displayTimeResult : TimeInterval -> Html Msg
displayTimeResult result =
    div [ testid "time-result" ] [ text <| TimeInterval.displayTwoDecimals result ]


viewSnackbar : String -> Html Msg
viewSnackbar snackbarText =
    div [ style "border" "solid black 2px" ] [ text snackbarText ]


viewEvaluationMessage : EvaluationMessage -> Html Msg
viewEvaluationMessage message =
    case message of
        NoEvaluationMessage ->
            div [] [ text "Auto-deploy works!" ]

        CorrectEvaluation ->
            div [ testid "correct-evaluation-message" ] [ text "Correct" ]

        WrongEvaluation ->
            div [ testid "wrong-evaluation-message" ] [ text "Wrong" ]
