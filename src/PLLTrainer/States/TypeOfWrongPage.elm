module PLLTrainer.States.TypeOfWrongPage exposing (Arguments, Transitions, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
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
view shared transitions arguments =
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                let
                    noMovesCube =
                        arguments.expectedCubeState
                            |> Cube.applyAlgorithm
                                (Algorithm.inverse <|
                                    PLLTrainer.TestCase.toAlg
                                        { addFinalReorientationToAlgorithm = True }
                                        shared.user
                                        arguments.testCase
                                )

                    nearlyThereCube =
                        arguments.expectedCubeState

                    cubeSize =
                        ViewportSize.minDimension shared.viewportSize // 7

                    buttonSize =
                        ViewportSize.minDimension shared.viewportSize // 40

                    fontSize =
                        ViewportSize.minDimension shared.viewportSize // 30

                    headerSize =
                        fontSize * 4 // 3

                    elementSeparation =
                        ViewportSize.minDimension shared.viewportSize // 30
                in
                column
                    [ testid "type-of-wrong-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , width fill
                    , centerY
                    , UI.paddingAll.large
                    , spacing elementSeparation
                    , Font.size fontSize
                    ]
                    [ paragraph [ centerX, Font.center, Font.bold, Font.size headerSize ] [ text "Choose the case that fits your cube state:" ]
                    , paragraph [ testid "no-move-explanation", centerX, Font.center ] [ text "1. I didn't apply any moves to the cube" ]
                    , row [ centerX ]
                        [ ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "no-move-cube-state-front" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            noMovesCube
                        , ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "no-move-cube-state-back" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            noMovesCube
                        ]
                    , PLLTrainer.ButtonWithShortcut.viewSmall
                        shared.hardwareAvailable
                        [ testid "no-move-button", centerX ]
                        shared.palette
                        { onPress = Just transitions.noMoveWasApplied
                        , color = shared.palette.primaryButton
                        , labelText = "No Moves Applied"
                        , keyboardShortcut = Key.One
                        , disabledStyling = False
                        }
                        (UI.viewButton.customSize buttonSize)
                    , paragraph [ testid "nearly-there-explanation", centerX, Font.center ]
                        [ text "2. I can get to the expected state. I for example just got the AUF wrong"
                        ]
                    , row [ centerX ]
                        [ ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "nearly-there-cube-state-front" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            nearlyThereCube
                        , ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "nearly-there-cube-state-back" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            nearlyThereCube
                        ]
                    , PLLTrainer.ButtonWithShortcut.viewSmall
                        shared.hardwareAvailable
                        [ testid "nearly-there-button", centerX ]
                        shared.palette
                        { onPress = Just transitions.expectedStateWasReached
                        , color = shared.palette.primaryButton
                        , labelText = "Cube Is As Expected"
                        , keyboardShortcut = Key.Two
                        , disabledStyling = False
                        }
                        (UI.viewButton.customSize buttonSize)
                    , paragraph [ testid "unrecoverable-explanation", centerX, Font.center ]
                        [ text "3. I can't get to either of the above states, so I will just solve it to reset it" ]
                    , PLLTrainer.ButtonWithShortcut.viewSmall
                        shared.hardwareAvailable
                        [ testid "unrecoverable-button", centerX ]
                        shared.palette
                        { onPress = Just transitions.cubeUnrecoverable
                        , color = shared.palette.primaryButton
                        , labelText = "Reset To Solved"
                        , keyboardShortcut = Key.Three
                        , disabledStyling = False
                        }
                        (UI.viewButton.customSize buttonSize)
                    ]
            )
    }
