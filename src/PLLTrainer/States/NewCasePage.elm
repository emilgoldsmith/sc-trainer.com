module PLLTrainer.States.NewCasePage exposing (Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import FeedbackButton
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
    { overlays = View.buildOverlays [ FeedbackButton.overlay viewportSize ]
    , body =
        View.FullScreen <|
            column
                [ testid "new-case-page-container"
                , centerX
                , centerY
                , width (fill |> maximum 700)
                , UI.paddingAll.veryLarge
                , spacing (ViewportSize.minDimension viewportSize // 20)
                ]
                [ paragraph [ testid "new-case-explanation", centerX, UI.fontSize.large ]
                    [ text "A new case is coming up"
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    hardwareAvailable
                    [ testid "start-test-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Next"
                    , keyboardShortcut = Key.Space
                    , color = palette.primary
                    }
                    (UI.viewButton.customSize <| ViewportSize.minDimension viewportSize // 20)
                ]
    }
