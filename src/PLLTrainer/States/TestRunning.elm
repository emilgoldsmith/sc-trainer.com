module PLLTrainer.States.TestRunning exposing (Arguments(..), Model, Msg, state, tESTONLYUpdateMemoizedCube)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
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
            , Task.perform (always <| toMsg CountdownIntervalPassed) <| Process.sleep countdownInterval
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


countdownInterval : Float
countdownInterval =
    600


type Msg
    = MillisecondsPassed Float
    | CountdownIntervalPassed
    | TESTONLYUpdateMemoizedCube Cube


tESTONLYUpdateMemoizedCube : Cube -> Msg
tESTONLYUpdateMemoizedCube =
    TESTONLYUpdateMemoizedCube


update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
update toMsg msg model =
    case ( model, msg ) of
        ( GetReadyModel modelRecord, CountdownIntervalPassed ) ->
            if modelRecord.countdown > 1 then
                ( GetReadyModel { modelRecord | countdown = modelRecord.countdown - 1 }
                , Task.perform
                    (always <| toMsg CountdownIntervalPassed)
                    (Process.sleep countdownInterval)
                )

            else
                ( model
                , Task.perform
                    (always <| modelRecord.startTest)
                    (Process.sleep countdownInterval)
                )

        ( TestRunningModel modelRecord, MillisecondsPassed timeDelta ) ->
            ( TestRunningModel { modelRecord | elapsedTime = TimeInterval.increment timeDelta modelRecord.elapsedTime }
            , Cmd.none
            )

        ( TestRunningModel modelRecord, TESTONLYUpdateMemoizedCube newCube ) ->
            ( TestRunningModel { modelRecord | memoizedCube = newCube }
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
                GetReadyModel { countdown } ->
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
                    , isGettingReady = Just countdown
                    , mainContainerTestId = "test-running-container-get-ready"
                    , cubeTestId = "cube-placeholder"
                    }

                TestRunningModel { memoizedCube, elapsedTime } ->
                    { cube = memoizedCube
                    , elapsedTime = elapsedTime
                    , cubeTheme = User.cubeTheme user
                    , isGettingReady = Nothing
                    , mainContainerTestId = "test-running-container"
                    , cubeTestId = "test-case"
                    }
    in
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                el
                    [ testid parameters.mainContainerTestId
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , width fill
                    , height fill
                    , inFront <|
                        case parameters.isGettingReady of
                            Just countdown ->
                                let
                                    red =
                                        rgb255 255 0 0

                                    yellow =
                                        rgb255 255 255 0

                                    green =
                                        rgb255 0 255 0

                                    circleSize =
                                        ViewportSize.minDimension viewportSize // 8

                                    circleColor =
                                        if countdown > 2 then
                                            red

                                        else if countdown == 2 then
                                            yellow

                                        else
                                            green
                                in
                                el
                                    [ testid "get-ready-overlay"
                                    , width fill
                                    , height fill
                                    , Background.color (rgba255 0 0 0 0.7)
                                    ]
                                <|
                                    column
                                        [ centerX
                                        , centerY
                                        , Font.center
                                        , Font.size (ViewportSize.minDimension viewportSize // 10)
                                        , spacing (ViewportSize.minDimension viewportSize // 20)
                                        , Background.color (rgba255 255 255 255 0.3)
                                        , padding (ViewportSize.minDimension viewportSize // 40)
                                        , Border.rounded (ViewportSize.minDimension viewportSize // 40)
                                        ]
                                        [ paragraph [ testid "get-ready-explanation" ] [ text "Get Ready" ]
                                        , paragraph [] [ text "Go To Home Grip" ]
                                        , row [ centerX, spacing (ViewportSize.minDimension viewportSize // 30) ]
                                            [ circle circleSize circleColor
                                            , circle circleSize circleColor
                                            , circle circleSize circleColor
                                            ]
                                        ]

                            Nothing ->
                                none
                    ]
                <|
                    column
                        [ centerX
                        , centerY
                        , spacing (ViewportSize.minDimension viewportSize // 10)
                        ]
                        [ el [ centerX ] <|
                            ViewCube.view cubeViewOptions
                                [ htmlTestid parameters.cubeTestId ]
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
            )
    }


circle : Int -> Color -> Element msg
circle size color =
    el
        [ width <| px size
        , height <| px size
        , Border.rounded size
        , Background.color color
        ]
        none


msgToString : Msg -> String
msgToString msg =
    case msg of
        MillisecondsPassed _ ->
            "MillisecondsPassed"

        CountdownIntervalPassed ->
            "CountdownIntervalPassed"

        TESTONLYUpdateMemoizedCube _ ->
            "TESTONLYUpdateMemoizedCube"


modelToString : Model msg -> String
modelToString model =
    case model of
        GetReadyModel _ ->
            "GetReadyModel"

        TestRunningModel _ ->
            "TestRunningModel"
