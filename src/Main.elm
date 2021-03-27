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


type EvaluationMessage
    = NoEvaluationMessage
    | CorrectEvaluation
    | WrongEvaluation


type Msg
    = IgnoredKeyEvent
    | StartTest TestStartData
    | MillisecondsPassed Float
    | EndTest (Maybe Time.Posix)
    | EndIgnoringKeyPressesAfterTransition
    | SpaceStarted
    | SpaceEnded
    | WStarted
    | WEnded
    | WindowResized Int Int


type TestStartData
    = NothingGenerated
    | AlgGenerated Algorithm.Algorithm
    | EverythingGenerated Algorithm.Algorithm Time.Posix


type alias IsRepeatedKeyPressFlag =
    Bool


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
                            (\key ->
                                if key == Space then
                                    StartTest NothingGenerated

                                else
                                    IgnoredKeyEvent
                            )
                            decodeNonRepeatedKeyEvent

                TestRunning _ _ _ ->
                    Sub.batch
                        [ Events.onKeyDown <|
                            Decode.map
                                (always <| EndTest Nothing)
                                decodeNonRepeatedKeyEvent
                        , Events.onMouseDown <|
                            Decode.succeed <|
                                EndTest Nothing
                        , Events.onAnimationFrameDelta MillisecondsPassed
                        ]

                EvaluatingResult { ignoringKeyPressesAfterTransition, spacePressStarted, wPressStarted } ->
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

                                            _ ->
                                                IgnoredKeyEvent
                                    )
                                    decodeNonRepeatedKeyEvent
                            , Events.onKeyUp <|
                                Decode.map
                                    (\key ->
                                        case key of
                                            Space ->
                                                if spacePressStarted then
                                                    SpaceEnded

                                                else
                                                    IgnoredKeyEvent

                                            W ->
                                                if wPressStarted then
                                                    WEnded

                                                else
                                                    IgnoredKeyEvent

                                            _ ->
                                                IgnoredKeyEvent
                                    )
                                    decodeNonRepeatedKeyEvent
                            ]

        globalSubscriptions =
            Events.onResize WindowResized
    in
    Sub.batch [ trainerSubscriptions, globalSubscriptions ]


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

                EvaluatingResult keyStates ->
                    case msg of
                        EndIgnoringKeyPressesAfterTransition ->
                            ( { model | trainerState = EvaluatingResult { keyStates | ignoringKeyPressesAfterTransition = False } }, Cmd.none )

                        SpaceStarted ->
                            ( { model | trainerState = EvaluatingResult { keyStates | spacePressStarted = True } }, Cmd.none )

                        WStarted ->
                            ( { model | trainerState = EvaluatingResult { keyStates | wPressStarted = True } }, Cmd.none )

                        SpaceEnded ->
                            ( { model | trainerState = BetweenTests CorrectEvaluation }, Cmd.none )

                        WEnded ->
                            ( { model | trainerState = BetweenTests WrongEvaluation }, Cmd.none )

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
