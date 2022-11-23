module PLLTrainer.States.AlgorithmDrillerExplanationPage exposing (Transitions, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import ErrorMessage
import Html.Attributes
import Key
import PLL
import PLLRecognition
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.TestCase
import Shared
import UI
import User
import View
import ViewCube


state : Shared.Model -> Transitions msg -> Arguments msg -> PLLTrainer.State.State msg () ()
state shared transitions arguments =
    PLLTrainer.State.static
        { view = view shared transitions arguments
        , nonRepeatedKeyUpHandler =
            Just
                (\key ->
                    case key of
                        Key.Space ->
                            transitions.startDrills

                        _ ->
                            transitions.noOp
                )
        }



-- TRANSITIONS AND ARGUMENTS


type alias Transitions msg =
    { startDrills : msg
    , noOp : msg
    }


type alias Arguments msg =
    { testCase : PLLTrainer.TestCase.TestCase
    , wasCorrect : Bool
    , sendError : String -> msg
    }



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments msg -> PLLTrainer.State.View msg
view shared transitions { testCase, wasCorrect, sendError } =
    let
        maybePLLAlgorithm =
            User.getPLLAlgorithm (PLLTrainer.TestCase.pll testCase) shared.user

        recognitionSpecResult =
            case maybePLLAlgorithm of
                Nothing ->
                    Err "No PLL algorithm was stored for this case"

                Just pllAlgorithm ->
                    case
                        PLL.getUniqueTwoSidedRecognitionSpecification
                            { pllAlgorithmUsed = pllAlgorithm
                            , recognitionAngle = PLL.ufrRecognitionAngle
                            , preAUF = PLLTrainer.TestCase.preAUF testCase
                            , pll = PLLTrainer.TestCase.pll testCase
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
                el
                    [ testid "algorithm-driller-explanation-page-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , width fill
                    , height fill
                    , scrollbarY
                    ]
                <|
                    column
                        [ centerX
                        , centerY
                        , width (fill |> maximum 700)
                        , UI.paddingAll.veryLarge
                        , UI.spacingVertical.medium
                        ]
                        [ textColumn
                            [ testid "algorithm-driller-explanation"
                            , width fill
                            , centerX
                            , UI.fontSize.medium
                            , UI.spacingVertical.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Font.center, centerX ]
                                [ if wasCorrect then
                                    text "A Bit More Practice Needed"

                                  else
                                    text "Time To Drill Your Algorithm"
                                ]
                            , paragraph []
                                [ if wasCorrect then
                                    el [ testid "correct-text" ] <| text "Good job solving the case correctly! Since you did it slower than your target parameters it seems a bit more practice is needed though, maybe to derust the algorithm or to learn it a bit better. "

                                  else
                                    el [ testid "wrong-text" ] <| text "It looks like this case was new to you. "
                                , text "This is therefore a prompt to just take some time to practice the case and algorithm that you just attempted and is shown below here again. Your aim should be to reach a level of comfort where you can recognize the case confidently, and execute the algorithm fluidly without looking at the cube. We don't recommend continuing on with other cases until you have reached that level of confidence with this case."
                                ]
                            , paragraph []
                                [ text "You are of course welcome to close the app and return when you are ready, but if you have kept the app open and finished practicing feel free to press the continue button. This will lead you to a little test that will time you on this case until you get it correct three times in a row. In addition it only counts a case as correct if executed fast enough for the target parameters you have set for a case being learned. When you have passed three times in a row you will go back into the normal flow of practicing cases."
                                ]
                            ]
                        , el [ centerX ] <|
                            ViewCube.view shared.cubeViewOptions
                                [ htmlTestid "case-to-drill" ]
                                { pixelSize = 200
                                , displayAngle = Cube.ufrDisplayAngle
                                , annotateFaces = False
                                , theme = User.cubeTheme shared.user
                                }
                            <|
                                PLLTrainer.TestCase.toCube shared.user testCase
                        , paragraph
                            [ testid "algorithm-to-drill"
                            , centerX
                            , Font.bold
                            , Font.center
                            , UI.fontSize.large
                            ]
                            [ text
                                (testCase
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
                                    , sendError = sendError errorDescription
                                    }

                            Ok recognitionSpec ->
                                column
                                    [ testid "recognition-explanation"
                                    , centerX
                                    , UI.spacingVertical.extremelySmall
                                    , UI.fontSize.medium
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
                        , PLLTrainer.ButtonWithShortcut.view
                            shared.hardwareAvailable
                            [ testid "continue-button"
                            , centerX
                            ]
                            { onPress = Just transitions.startDrills
                            , labelText = "Continue"
                            , keyboardShortcut = Key.Space
                            , color = shared.palette.primaryButton
                            }
                            UI.viewButton.large
                        ]
            )
    }
