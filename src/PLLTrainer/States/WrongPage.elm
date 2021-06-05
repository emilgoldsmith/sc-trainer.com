module PLLTrainer.States.WrongPage exposing (Arguments, Transitions, state)

import Algorithm
import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import Json.Decode
import Key
import PLL
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import StatefulPage
import TimeInterval exposing (TimeInterval)
import UI
import View
import ViewCube
import ViewportSize exposing (ViewportSize)
import WebResource


state : Shared.Model -> Transitions msg -> Arguments -> { view : StatefulPage.StateView msg, subscriptions : Sub msg }
state { viewportSize, palette, hardwareAvailable } transitions arguments =
    { view = view viewportSize palette hardwareAvailable transitions arguments
    , subscriptions = subscriptions transitions
    }


type alias Transitions msg =
    { startNextTest : msg
    , noOp : msg
    }


type alias Arguments =
    { expectedCubeState : Cube
    , testCase : TestCase
    }


subscriptions : Transitions msg -> Sub msg
subscriptions transitions =
    Browser.Events.onKeyUp <|
        Json.Decode.map
            (\key ->
                case key of
                    Key.Space ->
                        transitions.startNextTest

                    _ ->
                        transitions.noOp
            )
            Key.decodeNonRepeatedKeyEvent


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> Arguments -> StatefulPage.StateView msg
view viewportSize palette hardwareAvailable transitions arguments =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
    , body =
        let
            testCaseCube =
                Cube.applyAlgorithm
                    (Algorithm.inverse <| PLLTrainer.TestCase.toAlg arguments.testCase)
                    Cube.solved
        in
        View.FullScreen <|
            column
                [ testid "wrong-container"
                , centerX
                , centerY
                , spacing (ViewportSize.minDimension viewportSize // 20)
                ]
                [ el
                    [ centerX
                    , Font.size (ViewportSize.minDimension viewportSize // 20)
                    , testid "test-case-name"
                    ]
                  <|
                    text
                        ("The Correct Answer Was "
                            ++ PLL.getLetters (PLLTrainer.TestCase.pll arguments.testCase)
                            ++ "-perm:"
                        )
                , row
                    [ centerX
                    ]
                    [ ViewCube.uFRWithLetters [ htmlTestid "test-case-front" ]
                        (ViewportSize.minDimension viewportSize // 4)
                        testCaseCube
                    , ViewCube.uBLWithLetters [ htmlTestid "test-case-back" ]
                        (ViewportSize.minDimension viewportSize // 4)
                        testCaseCube
                    ]
                , paragraph
                    [ centerX
                    , Font.center
                    , Font.size (ViewportSize.minDimension viewportSize // 20)
                    , testid "expected-cube-state-text"
                    ]
                    [ text "Your Cube Should Now Look Like This:" ]
                , row
                    [ centerX
                    ]
                    [ ViewCube.uFRWithLetters [ htmlTestid "expected-cube-state-front" ] (ViewportSize.minDimension viewportSize // 4) arguments.expectedCubeState
                    , ViewCube.uBLWithLetters [ htmlTestid "expected-cube-state-back" ] (ViewportSize.minDimension viewportSize // 4) arguments.expectedCubeState
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    hardwareAvailable
                    [ testid "next-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startNextTest
                    , labelText = "Next"
                    , keyboardShortcut = Key.Space
                    , color = palette.primary
                    }
                    (UI.viewButton.customSize <| ViewportSize.minDimension viewportSize // 20)
                ]
    }
