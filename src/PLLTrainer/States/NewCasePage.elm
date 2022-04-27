module PLLTrainer.States.NewCasePage exposing (Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import View


state : Shared.Model -> Transitions msg -> PLLTrainer.State.State msg () ()
state { palette, hardwareAvailable } transitions =
    PLLTrainer.State.static
        { view = view palette hardwareAvailable transitions
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


view : UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> PLLTrainer.State.View msg
view palette hardwareAvailable transitions =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "new-case-page-container"
                , centerX
                , centerY
                , width (fill |> maximum 700)
                , UI.paddingAll.veryLarge
                , UI.spacingVertical.small
                ]
                [ textColumn
                    [ testid "new-case-explanation"
                    , width fill
                    , centerX
                    , UI.fontSize.medium
                    , UI.spacingVertical.small
                    ]
                    [ paragraph [ UI.fontSize.veryLarge, Font.center, centerX ] [ text "New Case Coming Up" ]
                    , paragraph []
                        [ text "Pay extra attention for this next case, as it will be used to determine how well you know it from before. Don't worry if you make a mistake though, the app will figure out that you have learned the case in time as you keep proving it."
                        ]
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    hardwareAvailable
                    [ testid "start-test-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Start"
                    , keyboardShortcut = Key.Space
                    , color = palette.primary
                    }
                    UI.viewButton.large
                ]
    }
