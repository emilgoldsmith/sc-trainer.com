module PLLTrainer.States.CorrectPage exposing (Transitions, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import FeedbackButton
import Json.Decode
import Key
import PLLTrainer.ButtonWithShortcut
import Shared
import StatefulPage
import TimeInterval exposing (TimeInterval)
import UI
import View
import ViewCube
import ViewportSize exposing (ViewportSize)
import WebResource


state : Shared.Model -> Transitions msg -> { view : StatefulPage.StateView msg, subscriptions : Sub msg }
state { viewportSize, palette, hardwareAvailable } transitions =
    { view = view viewportSize palette hardwareAvailable transitions
    , subscriptions = subscriptions transitions
    }


type alias Transitions msg =
    { startTest : msg
    , noOp : msg
    }


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


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> StatefulPage.StateView msg
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
