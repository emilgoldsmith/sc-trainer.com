module PLLTrainer.States.PickAUFPreferencesPage exposing (state)

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
import ViewportSize


state : Shared.Model -> Transitions msg -> PLLTrainer.State.State msg () ()
state shared transitions =
    PLLTrainer.State.static
        { view = view shared transitions
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    case key of
                        Key.Space ->
                            transitions.continue

                        _ ->
                            transitions.noOp
        }



-- VIEW


type alias Transitions msg =
    { continue : msg
    , noOp : msg
    }


view : Shared.Model -> Transitions msg -> PLLTrainer.State.View msg
view shared transitions =
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "pick-auf-preferences-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , centerX
                    , centerY
                    , spacing (ViewportSize.minDimension shared.viewportSize // 20)
                    ]
                    [ PLLTrainer.ButtonWithShortcut.view
                        shared.hardwareAvailable
                        [ testid "submit-button"
                        , centerX
                        ]
                        shared.palette
                        { onPress = Just transitions.continue
                        , labelText = "Submit"
                        , keyboardShortcut = Key.Enter
                        , color = shared.palette.primaryButton
                        , disabledStyling = False
                        }
                        (UI.viewButton.customSize <| ViewportSize.minDimension shared.viewportSize // 20)
                    ]
            )
    }
