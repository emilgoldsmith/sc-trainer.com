module PLLTrainer.States.CorrectPage exposing (Arguments, Transitions, state)

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
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                column
                    [ testid "correct-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
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
                        shared.palette
                        { onPress = Just transitions.startTest
                        , labelText = "Next"
                        , keyboardShortcut = Key.Space
                        , color = shared.palette.primaryButton
                        , disabledStyling = False
                        }
                        (UI.viewButton.customSize <| ViewportSize.minDimension shared.viewportSize // 20)
                    ]
            )
    }
