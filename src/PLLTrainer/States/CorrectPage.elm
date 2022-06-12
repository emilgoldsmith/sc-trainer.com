module PLLTrainer.States.CorrectPage exposing (Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import FeedbackButton
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import View
import ViewportSize


state : Shared.Model -> Arguments -> Transitions msg -> PLLTrainer.State.State msg () ()
state shared arguments transitions =
    PLLTrainer.State.static
        { view = view shared arguments transitions
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    case key of
                        Key.Space ->
                            transitions.startTest

                        _ ->
                            transitions.noOp
        }



-- TRANSITIONS AND ARGUMENTS


type alias Arguments =
    { wasNewCase : Bool
    }


type alias Transitions msg =
    { startTest : msg
    , noOp : msg
    }



-- VIEW


view : Shared.Model -> Arguments -> Transitions msg -> PLLTrainer.State.View msg
view shared { wasNewCase } transitions =
    { overlays = View.buildOverlays [ FeedbackButton.overlay shared.viewportSize ]
    , body =
        View.FullScreen <|
            column
                [ testid "correct-container"
                , centerX
                , centerY
                , spacing (ViewportSize.minDimension shared.viewportSize // 20)
                ]
                [ el
                    [ centerX
                    , Font.size (ViewportSize.minDimension shared.viewportSize // 20)
                    ]
                  <|
                    text "Correct!"
                , if wasNewCase then
                    paragraph
                        [ testid "good-job-text"
                        , Font.size (ViewportSize.minDimension shared.viewportSize // 30)
                        , UI.paddingHorizontal.extremelyLarge
                        , width (fill |> maximum 750)
                        , centerX
                        , Font.center
                        ]
                        [ text "Good Job! This case has been noted as already learned for you, so won't be focused much on until other cases have been learned."
                        ]

                  else
                    none
                , el
                    [ centerX
                    , Font.size (ViewportSize.minDimension shared.viewportSize // 20)
                    ]
                  <|
                    text "Continue When Ready"
                , PLLTrainer.ButtonWithShortcut.view
                    shared.hardwareAvailable
                    [ testid "next-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Next"
                    , keyboardShortcut = Key.Space
                    , color = shared.palette.primary
                    }
                    (UI.viewButton.customSize <| ViewportSize.minDimension shared.viewportSize // 20)
                ]
    }
