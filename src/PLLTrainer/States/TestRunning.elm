module PLLTrainer.States.TestRunning exposing (Model, Msg, state)

import Algorithm
import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import Json.Decode
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import StatefulPage
import TimeInterval exposing (TimeInterval)
import View
import ViewCube
import ViewportSize exposing (ViewportSize)


state :
    Shared.Model
    -> TestCase
    -> (Msg -> msg)
    ->
        { init : Model
        , view : Model -> StatefulPage.StateView msg
        , update : Msg -> Model -> Model
        , subscriptions : Sub msg
        }
state { viewportSize } testCase toMsg =
    { init = init
    , view = view viewportSize testCase
    , update = update toMsg
    , subscriptions = subscriptions toMsg
    }


type alias Model =
    { elapsedTime : TimeInterval }


type Msg
    = MillisecondsPassed Float


init : Model
init =
    { elapsedTime = TimeInterval.zero }


update : (Msg -> msg) -> Msg -> Model -> Model
update toMsg msg model =
    case msg of
        MillisecondsPassed timeDelta ->
            { model | elapsedTime = TimeInterval.increment timeDelta model.elapsedTime }


subscriptions : (Msg -> msg) -> Sub msg
subscriptions toMsg =
    Browser.Events.onAnimationFrameDelta (toMsg << MillisecondsPassed)


view : ViewportSize -> TestCase -> Model -> StatefulPage.StateView msg
view viewportSize testCase model =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
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
                        (Cube.solved |> Cube.applyAlgorithm (Algorithm.inverse (PLLTrainer.TestCase.toAlg testCase)))
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
