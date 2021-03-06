module PLLTrainer.States.TypeOfWrongPage exposing (Arguments, Transitions, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Key
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
                        Key.One ->
                            transitions.noMoveWasApplied

                        Key.Two ->
                            transitions.expectedStateWasReached

                        Key.Three ->
                            transitions.cubeUnrecoverable

                        _ ->
                            transitions.noOp
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { expectedCubeState : Cube
    , testCase : TestCase
    }


type alias Transitions msg =
    { noMoveWasApplied : msg
    , expectedStateWasReached : msg
    , cubeUnrecoverable : msg
    , noOp : msg
    }



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.View msg
view { user, viewportSize, palette, hardwareAvailable, cubeViewOptions } transitions arguments =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            let
                noMovesCube =
                    arguments.expectedCubeState |> Cube.applyAlgorithm (Algorithm.inverse <| PLLTrainer.TestCase.toAlg user arguments.testCase)

                nearlyThereCube =
                    arguments.expectedCubeState

                cubeSize =
                    ViewportSize.minDimension viewportSize // 7

                buttonSize =
                    ViewportSize.minDimension viewportSize // 40

                fontSize =
                    ViewportSize.minDimension viewportSize // 30

                headerSize =
                    fontSize * 4 // 3

                elementSeparation =
                    ViewportSize.minDimension viewportSize // 30
            in
            column
                [ testid "type-of-wrong-container"
                , width fill
                , centerY
                , UI.paddingAll.large
                , spacing elementSeparation
                , Font.size fontSize
                ]
                [ paragraph [ centerX, Font.center, Font.bold, Font.size headerSize ] [ text "Choose the case that fits your cube state:" ]
                , paragraph [ testid "no-move-explanation", centerX, Font.center ] [ text "1. I didn't apply any moves to the cube" ]
                , row [ centerX ]
                    [ ViewCube.view cubeViewOptions
                        [ htmlTestid "no-move-cube-state-front" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ufrDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme user
                        }
                        noMovesCube
                    , ViewCube.view cubeViewOptions
                        [ htmlTestid "no-move-cube-state-back" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ublDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme user
                        }
                        noMovesCube
                    ]
                , PLLTrainer.ButtonWithShortcut.viewSmall
                    hardwareAvailable
                    [ testid "no-move-button", centerX ]
                    { onPress = Just transitions.noMoveWasApplied, color = palette.primary, labelText = "No Moves Applied", keyboardShortcut = Key.One }
                    (UI.viewButton.customSize buttonSize)
                , paragraph [ testid "nearly-there-explanation", centerX, Font.center ]
                    [ text "2. I can get to the expected state. I for example just got the AUF wrong"
                    ]
                , row [ centerX ]
                    [ ViewCube.view cubeViewOptions
                        [ htmlTestid "nearly-there-cube-state-front" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ufrDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme user
                        }
                        nearlyThereCube
                    , ViewCube.view cubeViewOptions
                        [ htmlTestid "nearly-there-cube-state-back" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ublDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme user
                        }
                        nearlyThereCube
                    ]
                , PLLTrainer.ButtonWithShortcut.viewSmall
                    hardwareAvailable
                    [ testid "nearly-there-button", centerX ]
                    { onPress = Just transitions.expectedStateWasReached, color = palette.primary, labelText = "Cube Is As Expected", keyboardShortcut = Key.Two }
                    (UI.viewButton.customSize buttonSize)
                , paragraph [ testid "unrecoverable-explanation", centerX, Font.center ]
                    [ text "3. I can't get to either of the above states, so I will just solve it to reset it" ]
                , PLLTrainer.ButtonWithShortcut.viewSmall
                    hardwareAvailable
                    [ testid "unrecoverable-button", centerX ]
                    { onPress = Just transitions.cubeUnrecoverable
                    , color = palette.primary
                    , labelText = "Reset To Solved"
                    , keyboardShortcut = Key.Three
                    }
                    (UI.viewButton.customSize buttonSize)
                ]
    }
