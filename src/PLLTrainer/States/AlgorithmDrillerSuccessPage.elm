module PLLTrainer.States.AlgorithmDrillerSuccessPage exposing (Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import View
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> Transitions msg -> PLLTrainer.State.State msg () ()
state { viewportSize, palette, hardwareAvailable } transitions =
    PLLTrainer.State.static
        { view = view viewportSize palette hardwareAvailable transitions
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



-- VIEW


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> PLLTrainer.State.View msg
view viewportSize palette hardwareAvailable transitions =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "algorithm-driller-success-page-container"
                , centerX
                , centerY
                , spacing (ViewportSize.minDimension viewportSize // 10)
                , UI.paddingAll.veryLarge
                ]
                [ paragraph
                    [ centerX
                    , Font.center
                    , Font.bold
                    , Font.size (ViewportSize.minDimension viewportSize // 10)
                    ]
                    [ text "Success!"
                    ]
                , paragraph
                    [ testid "driller-success-explanation"
                    , centerX
                    , Font.center
                    , Font.size (ViewportSize.minDimension viewportSize // 20)
                    ]
                    [ text "Awesome, you now have a fundamental grasp of the case. Continue to return to the normal practice flow of cases" ]
                , PLLTrainer.ButtonWithShortcut.view
                    hardwareAvailable
                    [ testid "next-test-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Next"
                    , keyboardShortcut = Key.Space
                    , color = palette.primary
                    }
                    (UI.viewButton.customSize <| ViewportSize.minDimension viewportSize // 10)
                ]
    }
