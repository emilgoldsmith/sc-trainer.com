module PLLTrainer.States.WrongPage exposing (Arguments, Transitions, state)

import AUF
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import Key
import PLL
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import UI
import User
import View
import ViewCube
import ViewportSize


state : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.State msg () ()
state shared transitions arguments =
    PLLTrainer.State.static
        { view = view shared transitions arguments
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


view : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.View msg
view { palette, viewportSize, hardwareAvailable, user, cubeViewOptions } transitions arguments =
    { overlays = View.buildOverlays []
    , body =
        let
            testCaseCube =
                PLLTrainer.TestCase.toCube user arguments.testCase
        in
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "wrong-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
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
                        let
                            preAufString =
                                AUF.toString (PLLTrainer.TestCase.preAUF arguments.testCase)

                            postAufString =
                                AUF.toString (PLLTrainer.TestCase.postAUF arguments.testCase)
                        in
                        text
                            ("The Correct Answer Was "
                                ++ (if String.isEmpty preAufString then
                                        ""

                                    else
                                        preAufString ++ " "
                                   )
                                ++ "["
                                ++ PLL.getLetters (PLLTrainer.TestCase.pll arguments.testCase)
                                ++ "-perm]"
                                ++ (if String.isEmpty postAufString then
                                        ""

                                    else
                                        " "
                                            ++ postAufString
                                   )
                                ++ ":"
                            )
                    , row
                        [ centerX
                        ]
                        [ ViewCube.view cubeViewOptions
                            [ htmlTestid "test-case-front" ]
                            { pixelSize = ViewportSize.minDimension viewportSize // 4
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme user
                            }
                            testCaseCube
                        , ViewCube.view cubeViewOptions
                            [ htmlTestid "test-case-back" ]
                            { pixelSize = ViewportSize.minDimension viewportSize // 4
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme user
                            }
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
                        [ ViewCube.view cubeViewOptions
                            [ htmlTestid "expected-cube-state-front" ]
                            { pixelSize = ViewportSize.minDimension viewportSize // 4
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme user
                            }
                            arguments.expectedCubeState
                        , ViewCube.view cubeViewOptions
                            [ htmlTestid "expected-cube-state-back" ]
                            { pixelSize = ViewportSize.minDimension viewportSize // 4
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme user
                            }
                            arguments.expectedCubeState
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
            )
    }
