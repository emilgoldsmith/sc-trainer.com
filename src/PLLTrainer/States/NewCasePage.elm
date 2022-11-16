module PLLTrainer.States.NewCasePage exposing (Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
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
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "new-case-page-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
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
                            [ text "A new case can either be an entirely new PLL, a new recognition angle of a known PLL, or a new AUF for a known PLL. You should "
                            , el [ Font.bold ] <| text "pay extra attention for this next case"
                            , text ", as it will be used to determine how well you know it from before. Don't worry if you make a mistake though, the app will figure out that you have learned the case when it is tested again later."
                            ]
                        , paragraph []
                            [ text "If you're curious, the reason we even include the AUF at the end of a PLL as a new case, is because we want to incentivize thinking about and practicing how to finger trick each AUF. A bad final AUF can have a surprisingly big impact on your final time."
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
                        , color = palette.primaryButton
                        }
                        UI.viewButton.large
                    ]
            )
    }
