module PLLTrainer.States.CorrectPage exposing (Transitions, state)

import Browser.Events
import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import FeedbackButton
import Json.Decode
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
        , subscriptions = subscriptions transitions
        }



-- TRANSITIONS


type alias Transitions msg =
    { startTest : msg
    , noOp : msg
    }



-- SUBSCRIPTIONS


subscriptions : Transitions msg -> Sub msg
subscriptions transitions =
    Browser.Events.onKeyUp <|
        Json.Decode.map
            (\key ->
                case key of
                    Key.Space ->
                        transitions.startTest

                    _ ->
                        transitions.noOp
            )
            Key.decodeNonRepeatedKeyEvent



-- VIEW


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> PLLTrainer.State.View msg
view viewportSize palette hardwareAvailable transitions =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays [ FeedbackButton.overlay viewportSize ]
    , body =
        View.FullScreen <|
            column
                [ testid "correct-container"
                , centerX
                , centerY
                , spacing (ViewportSize.minDimension viewportSize // 20)
                ]
                [ el
                    [ centerX
                    , Font.size (ViewportSize.minDimension viewportSize // 20)
                    ]
                  <|
                    text "Correct!"
                , el
                    [ centerX
                    , Font.size (ViewportSize.minDimension viewportSize // 20)
                    ]
                  <|
                    text "Continue When Ready"
                , PLLTrainer.ButtonWithShortcut.view
                    hardwareAvailable
                    [ testid "next-button"
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
