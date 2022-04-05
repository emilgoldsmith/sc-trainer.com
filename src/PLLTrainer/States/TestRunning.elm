module PLLTrainer.States.TestRunning exposing (Arguments(..), Model, Msg, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Html.Events
import Json.Decode
import Key
import PLLTrainer.State
import PLLTrainer.Subscription
import Ports
import Process
import Shared
import Task
import TimeInterval exposing (TimeInterval)
import User
import View
import ViewCube
import ViewportSize


state :
    Shared.Model
    -> Arguments msg
    -> (Msg -> msg)
    -> Transitions msg
    -> PLLTrainer.State.State msg Msg Model
state shared arguments toMsg transitions =
    PLLTrainer.State.element
        { init = init arguments toMsg
        , view = view shared
        , update = update toMsg
        , subscriptions = subscriptions toMsg transitions
        }



-- ARGUMENTS AND TRANSITIONS


type Arguments msg
    = GetReadyArgument
    | TestRunningArgument { memoizedCube : Cube }


type alias Transitions msg =
    { startTest : msg
    , endTest : TimeInterval -> msg
    }



-- INIT


type Model
    = GetReadyModel { countdown : Int }
    | TestRunningModel { elapsedTime : TimeInterval, memoizedCube : Cube }


init : Arguments msg -> (Msg -> msg) -> ( Model, Cmd msg )
init arguments toMsg =
    case arguments of
        GetReadyArgument ->
            ( GetReadyModel { countdown = 3 }
            , Task.perform (always <| toMsg DecrementGetReadyCountdown) <| Process.sleep (1000 / 3)
            )

        TestRunningArgument { memoizedCube } ->
            ( TestRunningModel { elapsedTime = TimeInterval.zero, memoizedCube = memoizedCube }
            , Cmd.none
            )



-- UPDATE


type Msg
    = MillisecondsPassed Float
    | DecrementGetReadyCountdown


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update toMsg msg model =
    case ( model, msg ) of
        ( GetReadyModel modelRecord, DecrementGetReadyCountdown ) ->
            ( GetReadyModel { modelRecord | countdown = modelRecord.countdown - 1 }
            , Task.perform
                (always <| toMsg DecrementGetReadyCountdown)
                (Process.sleep (1000 / 3))
            )

        ( TestRunningModel modelRecord, MillisecondsPassed timeDelta ) ->
            ( TestRunningModel { modelRecord | elapsedTime = TimeInterval.increment timeDelta modelRecord.elapsedTime }
            , Cmd.none
            )

        _ ->
            ( model
            , Ports.logError <|
                "incompatible message with model state. Model was `"
                    ++ modelToString model
                    ++ "` and message was `"
                    ++ msgToString msg
                    ++ "`"
            )



-- SUBSCRIPTIONS


subscriptions : (Msg -> msg) -> Transitions msg -> Model -> PLLTrainer.Subscription.Subscription msg
subscriptions toMsg transitions model =
    case model of
        GetReadyModel _ ->
            PLLTrainer.Subscription.none

        TestRunningModel { elapsedTime } ->
            PLLTrainer.Subscription.browserEventsAndElementAttributes
                { browserEvents =
                    Sub.batch
                        [ Browser.Events.onKeyDown <|
                            Json.Decode.map
                                (always (transitions.endTest elapsedTime))
                                Key.decodeNonRepeatedKeyEvent
                        , Browser.Events.onMouseDown <|
                            Json.Decode.succeed (transitions.endTest elapsedTime)
                        , Browser.Events.onAnimationFrameDelta (toMsg << MillisecondsPassed)
                        ]
                , elementAttributes =
                    [ htmlAttribute <|
                        Html.Events.on "touchstart" <|
                            Json.Decode.succeed (transitions.endTest elapsedTime)
                    ]
                }



-- VIEW


view : Shared.Model -> Model -> PLLTrainer.State.View msg
view { viewportSize, cubeViewOptions, user } model =
    let
        parameters =
            case model of
                GetReadyModel _ ->
                    { cube = Cube.solved, elapsedTime = TimeInterval.zero }

                TestRunningModel { memoizedCube, elapsedTime } ->
                    { cube = memoizedCube, elapsedTime = elapsedTime }
    in
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "test-running-container"
                , centerX
                , centerY
                , spacing (ViewportSize.minDimension viewportSize // 10)
                ]
                [ el [ centerX ] <|
                    ViewCube.view cubeViewOptions
                        [ htmlTestid "test-case" ]
                        { pixelSize = ViewportSize.minDimension viewportSize // 2
                        , displayAngle = Cube.ufrDisplayAngle
                        , annotateFaces = False
                        , theme = User.cubeTheme user
                        }
                        parameters.cube
                , el
                    [ testid "timer"
                    , centerX
                    , Font.size (ViewportSize.minDimension viewportSize // 5)
                    ]
                  <|
                    text <|
                        TimeInterval.displayOneDecimal parameters.elapsedTime
                ]
    }


msgToString : Msg -> String
msgToString msg =
    case msg of
        MillisecondsPassed _ ->
            "MillisecondsPassed"

        DecrementGetReadyCountdown ->
            "DecrementGetReadyCountdown"


modelToString : Model -> String
modelToString model =
    case model of
        GetReadyModel _ ->
            "GetReadyModel"

        TestRunningModel _ ->
            "TestRunningModel"
