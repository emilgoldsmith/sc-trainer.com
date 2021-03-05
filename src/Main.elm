module Main exposing (main)

import Browser
import Browser.Events as Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Process
import Task
import Time


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
    | TestRunning { startTime : Time.Posix, currentTime : Time.Posix }
    | EvaluatingResult { correctKeyPressStarted : Bool, wrongKeyPressStarted : Bool }


allPressed : { correctKeyPressStarted : Bool, wrongKeyPressStarted : Bool } -> Bool
allPressed { correctKeyPressStarted, wrongKeyPressStarted } =
    correctKeyPressStarted && wrongKeyPressStarted


type EvaluationMessage
    = NoEvaluationMessage
    | CorrectEvaluation
    | WrongEvaluation


type Msg
    = KeyUp Key
    | KeyDown Key
    | DeleteOldestSnackbar
    | StartTest Time.Posix
    | UpdateTimer Time.Posix


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

        TestRunning _ ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map KeyDown
                        decodeKey
                , Events.onMouseDown <|
                    Decode.succeed
                        (KeyDown <| SomeKey "mouseDown")
                , Time.every 30 UpdateTimer
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
                            ( { model | trainerState = TestRunning { startTime = startTime, currentTime = startTime } }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                TestRunning timestamps ->
                    case msg of
                        KeyDown _ ->
                            ( { model | trainerState = EvaluatingResult { correctKeyPressStarted = False, wrongKeyPressStarted = False } }, Cmd.none )

                        UpdateTimer time ->
                            ( { model | trainerState = TestRunning { timestamps | currentTime = time } }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                EvaluatingResult ({ correctKeyPressStarted, wrongKeyPressStarted } as keyStates) ->
                    case msg of
                        KeyDown Space ->
                            ( { model | trainerState = EvaluatingResult { keyStates | correctKeyPressStarted = True } }, Cmd.none )

                        KeyUp Space ->
                            ( if correctKeyPressStarted then
                                { model | trainerState = BetweenTests CorrectEvaluation }

                              else
                                model
                            , Cmd.none
                            )

                        KeyDown W ->
                            ( { model | trainerState = EvaluatingResult { keyStates | wrongKeyPressStarted = True } }, Cmd.none )

                        KeyUp W ->
                            ( if wrongKeyPressStarted then
                                { model | trainerState = BetweenTests WrongEvaluation }

                              else
                                model
                            , Cmd.none
                            )

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
            div [ attribute "data-testid" "between-tests-container" ] [ text "Between Tests", viewEvaluationMessage message ]

        TestRunning timestamps ->
            div [ attribute "data-testid" "test-running-container" ] [ text "Test Running", div [ attribute "data-testid" "timer" ] [ text (Debug.log "timestamps" timestamps |> millisecondsElapsed |> displayTime) ] ]

        EvaluatingResult _ ->
            div [ attribute "data-testid" "evaluate-test-result-container" ] [ text <| "Evaluating Result" ]


millisecondsElapsed : { startTime : Time.Posix, currentTime : Time.Posix } -> Int
millisecondsElapsed { startTime, currentTime } =
    Time.posixToMillis currentTime - Time.posixToMillis startTime


displayTime : Int -> String
displayTime totalMilliseconds =
    let
        time =
            parseTime (Debug.log "millis" totalMilliseconds)
    in
    "0." ++ displayDeciseconds time


type alias TimeInterval =
    { milliseconds : Int, seconds : Int, minutes : Int, hours : Int }


parseTime : Int -> TimeInterval
parseTime totalMilliseconds =
    Debug.log "parsed time" { milliseconds = remainderBy 1000 totalMilliseconds, seconds = 0, minutes = 0, hours = 0 }


displayDeciseconds : TimeInterval -> String
displayDeciseconds time =
    let
        deciseconds =
            time.milliseconds // 100
    in
    String.fromInt deciseconds


viewSnackbar : String -> Html Msg
viewSnackbar snackbarText =
    div [ style "border" "solid black 2px" ] [ text snackbarText ]


viewEvaluationMessage : EvaluationMessage -> Html Msg
viewEvaluationMessage message =
    case message of
        NoEvaluationMessage ->
            div [] [ text "Auto-deploy works!" ]

        CorrectEvaluation ->
            div [ attribute "data-testid" "correct-evaluation-message" ] [ text "Correct" ]

        WrongEvaluation ->
            div [ attribute "data-testid" "wrong-evaluation-message" ] [ text "Wrong" ]
