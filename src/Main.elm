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
    ( { trainerState = BetweenTests, snackbars = [] }, Cmd.none )


type alias Model =
    { trainerState : TrainerState
    , snackbars : List String
    }


type TrainerState
    = BetweenTests
    | TestRunning
    | EvaluateResult Time.Posix


type Msg
    = KeyUp Key
    | KeyDown Key
    | StopTest Time.Posix
    | EvaluateWrong Time.Posix
    | EvaluateCorrect Time.Posix
    | DeleteOldestSnackbar


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

        _ ->
            SomeKey keyString


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.trainerState of
        BetweenTests ->
            Events.onKeyUp <| Decode.map KeyUp decodeKey

        TestRunning ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map KeyDown
                        decodeKey
                , Events.onMouseDown <|
                    Decode.succeed
                        (KeyDown <| SomeKey "mouseDown")
                ]

        _ ->
            Events.onKeyUp <| Decode.map KeyUp decodeKey


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DeleteOldestSnackbar ->
            ( { model | snackbars = List.take (List.length model.snackbars - 1) model.snackbars }, Cmd.none )

        _ ->
            case model.trainerState of
                BetweenTests ->
                    case msg of
                        KeyUp Space ->
                            ( { model | trainerState = TestRunning }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                TestRunning ->
                    case msg of
                        KeyDown _ ->
                            ( model, Task.perform StopTest Time.now )

                        StopTest timeStopped ->
                            ( { model | trainerState = EvaluateResult timeStopped }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                EvaluateResult timeStopped ->
                    case msg of
                        KeyUp Space ->
                            ( model, Task.perform EvaluateCorrect Time.now )

                        KeyUp W ->
                            ( model, Task.perform EvaluateWrong Time.now )

                        EvaluateCorrect timeEvaluated ->
                            if moreThanASecondLater timeStopped timeEvaluated then
                                ( { model | trainerState = BetweenTests }, Cmd.none )

                            else
                                addSnackbar model "correct too soon"

                        EvaluateWrong timeEvaluated ->
                            if moreThanASecondLater timeStopped timeEvaluated then
                                ( { model | trainerState = BetweenTests }, Cmd.none )

                            else
                                addSnackbar model "wrong too soon"

                        _ ->
                            ( model, Cmd.none )


addSnackbar : Model -> String -> ( Model, Cmd Msg )
addSnackbar model snackbarText =
    ( { model | snackbars = snackbarText :: model.snackbars }, Task.perform (always DeleteOldestSnackbar) (Process.sleep 3000) )


moreThanASecondLater : Time.Posix -> Time.Posix -> Bool
moreThanASecondLater first second =
    Time.posixToMillis second - Time.posixToMillis first > 400


view : Model -> Html Msg
view model =
    div [] [ viewState model, viewSnackbars model ]


viewSnackbars : Model -> Html Msg
viewSnackbars model =
    div [ style "position" "fixed", style "top" "20px", style "left" "50%" ] <| List.map viewSnackbar model.snackbars


viewState : Model -> Html Msg
viewState model =
    case model.trainerState of
        BetweenTests ->
            div [ attribute "data-testid" "between-tests-container" ] [ text "Between Tests" ]

        TestRunning ->
            div [ attribute "data-testid" "test-running-container" ] [ text "Test Running" ]

        EvaluateResult timeStopped ->
            div [ attribute "data-testid" "evaluate-test-result-container" ] [ text <| "Evaluating Result" ++ " " ++ (Time.toHour Time.utc timeStopped |> String.fromInt) ++ ":" ++ (Time.toMinute Time.utc timeStopped |> String.fromInt) ++ ":" ++ (Time.toSecond Time.utc timeStopped |> String.fromInt) ++ "." ++ (Time.toMillis Time.utc timeStopped |> String.fromInt) ]


viewSnackbar : String -> Html Msg
viewSnackbar snackbarText =
    div [ style "border" "solid black 2px" ] [ text snackbarText ]
