module PLLTrainer.States.AlgorithmDrillerExplanationPage exposing (Transitions, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.TestCase
import Shared
import UI
import User
import View
import ViewCube


state : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.State msg () ()
state shared transitions arguments =
    PLLTrainer.State.static
        { view = view shared transitions arguments
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    case key of
                        Key.Space ->
                            transitions.startDrills

                        _ ->
                            transitions.noOp
        }



-- TRANSITIONS


type alias Transitions msg =
    { startDrills : msg
    , noOp : msg
    }


type alias Arguments =
    { testCase : PLLTrainer.TestCase.TestCase
    , wasCorrect : Bool
    }



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.View msg
view shared transitions { testCase, wasCorrect } =
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "algorithm-driller-explanation-page-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , centerX
                    , centerY
                    , width (fill |> maximum 700)
                    , UI.paddingAll.veryLarge
                    , UI.spacingVertical.medium
                    , scrollbarY
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
                        ]
                        [ text
                            (testCase
                                |> PLLTrainer.TestCase.toAlg
                                    { addFinalReorientationToAlgorithm = False }
                                    shared.user
                                |> Algorithm.toString
                            )
                        ]
                    , PLLTrainer.ButtonWithShortcut.view
                        shared.hardwareAvailable
                        [ testid "continue-button"
                        , centerX
                        ]
                        { onPress = Just transitions.startDrills
                        , labelText = "Continue"
                        , keyboardShortcut = Key.Space
                        , color = shared.palette.primary
                        }
                        UI.viewButton.large
                    ]
            )
    }
