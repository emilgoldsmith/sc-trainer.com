module PLLTrainer.States.TestRunning exposing (Model, Msg, state)

import Algorithm
import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import Html.Events
import Json.Decode
import Key
import PLLTrainer.State
import PLLTrainer.Subscription
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import TimeInterval exposing (TimeInterval)
import View
import ViewCube
import ViewportSize exposing (ViewportSize)


state :
    Shared.Model
    -> TestCase
    -> (Msg -> msg)
    -> Transitions msg
    -> PLLTrainer.State.State msg Msg Model
state { viewportSize } testCase toMsg transitions =
    PLLTrainer.State.element
        { init = init
        , view = view viewportSize testCase
        , update = update
        , subscriptions = subscriptions toMsg transitions
        }



-- TRANSITIONS


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


view : ViewportSize -> TestCase -> Model -> PLLTrainer.State.View msg
view viewportSize testCase model =
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
                    ViewCube.uFRNoLetters [ htmlTestid "test-case" ] (ViewportSize.minDimension viewportSize // 2) <|
                        PLLTrainer.TestCase.toCube testCase
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
