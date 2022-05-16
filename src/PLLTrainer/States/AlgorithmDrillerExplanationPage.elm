module PLLTrainer.States.AlgorithmDrillerExplanationPage exposing (Transitions, state)

import Algorithm
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
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
state shared transitions { testCase } =
    PLLTrainer.State.static
        { view = view shared transitions testCase
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    case key of
                        Key.Space ->
                            transitions.startTest

                        _ ->
                            transitions.noOp
        }



-- TRANSITIONS


type alias Transitions msg =
    { startTest : msg
    , noOp : msg
    }


type alias Arguments =
    { testCase : PLLTrainer.TestCase.TestCase
    }



-- VIEW


view : Shared.Model -> Transitions msg -> PLLTrainer.TestCase.TestCase -> PLLTrainer.State.View msg
view shared transitions testCase =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "algorithm-driller-explanation-page-container"
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
                    [ paragraph [ UI.fontSize.veryLarge, Font.center, centerX ] [ text "Time To Drill Your Algorithm" ]
                    , paragraph []
                        [ text "It looks like you could use a bit more practice on this case. This is therefore a prompt to just take some time to practice the case and algorithm that you just attempted as is shown below here again. Your aim should be to reach a level of comfort where you can recognize the case confidently, and execute the algorithm fluidly without looking at the cube. We don't recommend continuing on with other cases until you have reached that level of confidence with this new case"
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
                            |> PLLTrainer.TestCase.toAlg shared.user
                            |> Algorithm.toString
                        )
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    shared.hardwareAvailable
                    [ testid "continue-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Continue"
                    , keyboardShortcut = Key.Space
                    , color = shared.palette.primary
                    }
                    UI.viewButton.large
                ]
    }
