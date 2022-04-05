module PLLTrainer.States.TestRunning exposing (Arguments(..), Model, Msg, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Background
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
    -> PLLTrainer.State.State msg Msg (Model msg)
state shared arguments toMsg =
    PLLTrainer.State.element
        { init = init arguments toMsg
        , view = view shared
        , update = update toMsg
        , subscriptions = subscriptions toMsg
        }



-- ARGUMENTS AND TRANSITIONS


type Arguments msg
    = GetReadyArgument { startTest : msg }
    | TestRunningArgument { memoizedCube : Cube, endTest : TimeInterval -> msg }



-- INIT


type Model msg
    = GetReadyModel { countdown : Int, startTest : msg }
    | TestRunningModel
        { elapsedTime : TimeInterval
        , memoizedCube : Cube
        , endTest : TimeInterval -> msg
        }


init : Arguments msg -> (Msg -> msg) -> ( Model msg, Cmd msg )
init arguments toMsg =
    case arguments of
        GetReadyArgument { startTest } ->
            ( GetReadyModel { countdown = 3, startTest = startTest }
            , Task.perform (always <| toMsg DecrementGetReadyCountdown) <| Process.sleep (1000 / 3)
            )

        TestRunningArgument { memoizedCube, endTest } ->
            ( TestRunningModel
                { elapsedTime = TimeInterval.zero
                , memoizedCube = memoizedCube
                , endTest = endTest
                }
            , Cmd.none
            )



-- UPDATE


type Msg
    = MillisecondsPassed Float
    | DecrementGetReadyCountdown


update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
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


subscriptions : (Msg -> msg) -> Model msg -> PLLTrainer.Subscription.Subscription msg
subscriptions toMsg model =
    case model of
        GetReadyModel _ ->
            PLLTrainer.Subscription.none

        TestRunningModel { elapsedTime, endTest } ->
            PLLTrainer.Subscription.browserEventsAndElementAttributes
                { browserEvents =
                    Sub.batch
                        [ Browser.Events.onKeyDown <|
                            Json.Decode.map
                                (always (endTest elapsedTime))
                                Key.decodeNonRepeatedKeyEvent
                        , Browser.Events.onMouseDown <|
                            Json.Decode.succeed (endTest elapsedTime)
                        , Browser.Events.onAnimationFrameDelta (toMsg << MillisecondsPassed)
                        ]
                , elementAttributes =
                    [ htmlAttribute <|
                        Html.Events.on "touchstart" <|
                            Json.Decode.succeed (endTest elapsedTime)
                    ]
                }



-- VIEW


view : Shared.Model -> Model msg -> PLLTrainer.State.View msg
view { viewportSize, cubeViewOptions, user } model =
    let
        black =
            ( 0, 0, 0 )

        grey =
            ( 100, 100, 100 )

        parameters =
            case model of
                GetReadyModel _ ->
                    { cube = Cube.solved
                    , elapsedTime = TimeInterval.zero
                    , cubeTheme =
                        { up = grey
                        , down = grey
                        , right = grey
                        , left = grey
                        , front = grey
                        , back = grey
                        , plastic = black
                        , annotations = black
                        }
                    , isGettingReady = True
                    }

                TestRunningModel { memoizedCube, elapsedTime } ->
                    { cube = memoizedCube
                    , elapsedTime = elapsedTime
                    , cubeTheme = User.cubeTheme user
                    , isGettingReady = False
                    }
    in
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            el
                [ width fill
                , height fill
                , inFront <|
                    if parameters.isGettingReady then
                        el
                            [ width fill
                            , height fill
                            , Element.Background.color (rgba255 0 0 0 0.7)
                            ]
                        <|
                            column [ centerX, centerY ] []

                    else
                        none
                ]
            <|
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
                            , theme = parameters.cubeTheme
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


modelToString : Model msg -> String
modelToString model =
    case model of
        GetReadyModel _ ->
            "GetReadyModel"

        TestRunningModel _ ->
            "TestRunningModel"
