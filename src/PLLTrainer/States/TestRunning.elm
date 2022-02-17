module PLLTrainer.States.TestRunning exposing (Arguments, Model, Msg, state)

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
import Shared
import TimeInterval exposing (TimeInterval)
import View
import ViewCube
import ViewportSize


state :
    Shared.Model
    -> Arguments
    -> (Msg -> msg)
    -> Transitions msg
    -> PLLTrainer.State.State msg Msg Model
state shared { memoizedCube } toMsg transitions =
    PLLTrainer.State.element
        { init = init
        , view = view shared memoizedCube
        , update = update
        , subscriptions = subscriptions toMsg transitions
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { memoizedCube : Cube
    }


type alias Transitions msg =
    { endTest : msg
    }



-- INIT


type alias Model =
    { elapsedTime : TimeInterval }


init : ( Model, Cmd msg )
init =
    ( { elapsedTime = TimeInterval.zero }, Cmd.none )



-- UPDATE


type Msg
    = MillisecondsPassed Float


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        MillisecondsPassed timeDelta ->
            ( { model | elapsedTime = TimeInterval.increment timeDelta model.elapsedTime }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : (Msg -> msg) -> Transitions msg -> Model -> PLLTrainer.Subscription.Subscription msg
subscriptions toMsg transitions _ =
    PLLTrainer.Subscription.browserEventsAndElementAttributes
        { browserEvents =
            Sub.batch
                [ Browser.Events.onKeyDown <|
                    Json.Decode.map
                        (always transitions.endTest)
                        Key.decodeNonRepeatedKeyEvent
                , Browser.Events.onMouseDown <|
                    Json.Decode.succeed transitions.endTest
                , Browser.Events.onAnimationFrameDelta (toMsg << MillisecondsPassed)
                ]
        , elementAttributes =
            [ htmlAttribute <|
                Html.Events.on "touchstart" <|
                    Json.Decode.succeed transitions.endTest
            ]
        }



-- VIEW


view : Shared.Model -> Cube -> Model -> PLLTrainer.State.View msg
view { viewportSize, cubeViewOptions } memoizedCube model =
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
                        }
                        memoizedCube
                , el
                    [ testid "timer"
                    , centerX
                    , Font.size (ViewportSize.minDimension viewportSize // 5)
                    ]
                  <|
                    text <|
                        TimeInterval.displayOneDecimal model.elapsedTime
                ]
    }
