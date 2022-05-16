module PLLTrainer.States.AlgorithmDrillerStatusPage exposing (Transitions, state)

import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import User
import View
import ViewCube
import ViewportSize


state : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.State msg () ()
state shared transitions arguments =
    PLLTrainer.State.static
        { view = view shared transitions arguments
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
    { expectedCube : Cube
    }



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments -> PLLTrainer.State.View msg
view shared transitions { expectedCube } =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "algorithm-driller-status-page-container"
                , centerX
                , centerY
                , width (fill |> maximum 700)
                , UI.paddingAll.veryLarge
                , UI.spacingVertical.medium
                ]
                [ paragraph
                    [ Font.size (ViewportSize.minDimension shared.viewportSize // 15)
                    , Font.bold
                    , centerX
                    , Font.center
                    ]
                    [ el [ testid "correct-consecutive-attempts-left" ] <|
                        text "3"
                    , text " Correct Attempts Remaining"
                    ]
                , paragraph
                    [ Font.size (ViewportSize.minDimension shared.viewportSize // 25)
                    , centerX
                    , Font.center
                    ]
                    [ text "Your cube should now look like this:"
                    ]
                , row [ centerX ]
                    [ ViewCube.view
                        shared.cubeViewOptions
                        [ htmlTestid "expected-cube-state-front" ]
                        { pixelSize = ViewportSize.minDimension shared.viewportSize // 3
                        , displayAngle = Cube.ufrDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme shared.user
                        }
                        expectedCube
                    , ViewCube.view
                        shared.cubeViewOptions
                        [ htmlTestid "expected-cube-state-back" ]
                        { pixelSize = ViewportSize.minDimension shared.viewportSize // 3
                        , displayAngle = Cube.ublDisplayAngle
                        , annotateFaces = True
                        , theme = User.cubeTheme shared.user
                        }
                        expectedCube
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    shared.hardwareAvailable
                    [ testid "start-test-button"
                    , centerX
                    ]
                    { onPress = Just transitions.startTest
                    , labelText = "Next Test"
                    , keyboardShortcut = Key.Space
                    , color = shared.palette.primary
                    }
                    (UI.viewButton.customSize <| ViewportSize.minDimension shared.viewportSize // 25)
                ]
    }
