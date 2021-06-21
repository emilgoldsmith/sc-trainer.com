module PLLTrainer.States.WrongPage exposing (Arguments, Transitions, state)

import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import FeedbackButton
import Key
import PLL
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import UI
import View
import ViewCube
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.State msg () ()
state { viewportSize, palette, hardwareAvailable } transitions arguments =
    PLLTrainer.State.static
        { view = view viewportSize palette hardwareAvailable transitions arguments
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    case key of
                        Key.Space ->
                            transitions.startNextTest

                        _ ->
                            transitions.noOp
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { expectedCubeState : Cube
    , testCase : TestCase
    }


type alias Transitions msg =
    { startNextTest : msg
    , noOp : msg
    }



-- VIEW


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> Arguments -> PLLTrainer.State.View msg
view viewportSize palette hardwareAvailable transitions arguments =
    { overlays = View.buildOverlays [ FeedbackButton.overlay viewportSize ]
    , body =
        let
            testCaseCube =
                PLLTrainer.TestCase.toCube arguments.testCase
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
