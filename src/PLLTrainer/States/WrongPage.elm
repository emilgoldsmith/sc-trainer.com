module PLLTrainer.States.WrongPage exposing (Arguments, Transitions, state)

import AUF
import Algorithm
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import ErrorMessage
import Html.Attributes
import Key
import PLL
import PLLRecognition
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.TestCase exposing (TestCase)
import Shared
import UI
import User
import View
import ViewCube
import ViewportSize


state : Shared.Model -> Transitions msg -> Arguments msg -> PLLTrainer.State.State msg () ()
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


type alias Arguments msg =
    { expectedCubeState : Cube
    , testCase : TestCase
    , sendError : String -> msg
    }


type alias Transitions msg =
    { startNextTest : msg
    , noOp : msg
    }



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments msg -> PLLTrainer.State.View msg
view shared transitions arguments =
    let
        testCaseCube =
            PLLTrainer.TestCase.toCube shared.user arguments.testCase

        cubePixelSize =
            ViewportSize.minDimension shared.viewportSize // 5

        largeTextSize =
            ViewportSize.minDimension shared.viewportSize // 25

        maybePLLAlgorithm =
            User.getPLLAlgorithm (PLLTrainer.TestCase.pll arguments.testCase) shared.user

        recognitionSpecResult =
            case maybePLLAlgorithm of
                Nothing ->
                    Err "No PLL algorithm was stored for this case"

                Just pllAlgorithm ->
                    case
                        PLL.getUniqueTwoSidedRecognitionSpecification
                            { pllAlgorithmUsed = pllAlgorithm
                            , recognitionAngle = PLL.ufrRecognitionAngle
                            , preAUF = PLLTrainer.TestCase.preAUF arguments.testCase
                            , pll = PLLTrainer.TestCase.pll arguments.testCase
                            }
                    of
                        Err (PLL.IncorrectPLLAlgorithm _ _) ->
                            Err "Stored PLL algorithm doesn't solve the case"

                        Ok recognitionSpec ->
                            Ok recognitionSpec
    in
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "wrong-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , centerX
                    , centerY
                    , spacing largeTextSize
                    ]
                    [ el
                        [ centerX
                        , Font.size largeTextSize
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
                        [ ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "test-case-front" ]
                            { pixelSize = cubePixelSize
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            testCaseCube
                        , ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "test-case-back" ]
                            { pixelSize = cubePixelSize
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            testCaseCube
                        ]
                    , paragraph
                        [ centerX
                        , Font.center
                        , Font.size largeTextSize
                        , testid "expected-cube-state-text"
                        ]
                        [ text "Your Cube Should Now Look Like This:" ]
                    , row
                        [ centerX
                        ]
                        [ ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "expected-cube-state-front" ]
                            { pixelSize = cubePixelSize
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            arguments.expectedCubeState
                        , ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "expected-cube-state-back" ]
                            { pixelSize = cubePixelSize
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            arguments.expectedCubeState
                        ]
                    , PLLTrainer.ButtonWithShortcut.view
                        shared.hardwareAvailable
                        [ testid "next-button"
                        , centerX
                        ]
                        { onPress = Just transitions.startNextTest
                        , labelText = "Next"
                        , keyboardShortcut = Key.Space
                        , color = shared.palette.primaryButton
                        }
                        (UI.viewButton.customSize <| largeTextSize)
                    , paragraph [ centerX, Font.center ]
                        [ el [ Font.bold ] <| text "Algorithm: "
                        , el [ testid "algorithm" ] <|
                            text
                                (arguments.testCase
                                    |> PLLTrainer.TestCase.toAlg
                                        { addFinalReorientationToAlgorithm = False }
                                        shared.user
                                    |> Algorithm.toString
                                )
                        ]
                    , case recognitionSpecResult of
                        Err errorDescription ->
                            ErrorMessage.viewInline
                                shared.palette
                                { errorDescription = errorDescription
                                , sendError = arguments.sendError errorDescription
                                }

                        Ok recognitionSpec ->
                            column
                                [ testid "recognition-explanation"
                                , centerX
                                , UI.spacingVertical.extremelySmall
                                , UI.fontSize.medium
                                , Font.center
                                ]
                                [ paragraph
                                    []
                                    [ el [ Font.bold ] <| text "PLL Recognition: "
                                    , text (PLLRecognition.specToPLLRecognitionString recognitionSpec)
                                    ]
                                , paragraph []
                                    [ el [ Font.bold ] <| text "Post-AUF Recognition: "
                                    , text (PLLRecognition.specToPostAUFString recognitionSpec)
                                    ]
                                ]
                    ]
            )
    }
