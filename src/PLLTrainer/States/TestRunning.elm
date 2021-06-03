module PLLTrainer.States.TestRunning exposing (Model, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import StatefulPage
import TimeInterval exposing (TimeInterval)
import View
import ViewCube
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> TestCase -> { init : Model, view : Model -> StatefulPage.StateView msg }
state { viewportSize } testCase =
    { init = init
    , view = view viewportSize testCase
    }


type alias Model =
    TimeInterval


init : Model
init =
    TimeInterval.zero


view : ViewportSize -> TestCase -> Model -> StatefulPage.StateView msg
view viewportSize testCase elapsedTime =
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
                        TimeInterval.displayOneDecimal elapsedTime
                ]
    }
