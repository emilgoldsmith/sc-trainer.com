module PLLTrainer.States.StartPage exposing (Transitions, state)

import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import View
import ViewCube
import ViewportSize exposing (ViewportSize)
import WebResource


state : Shared.Model -> Transitions msg -> PLLTrainer.State.State msg () ()
state { viewportSize, palette, hardwareAvailable } transitions =
    PLLTrainer.State.static
        { view = view viewportSize palette hardwareAvailable transitions
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    if key == Key.Space then
                        transitions.startTest

                    else
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
            el
                [ testid "start-page-container"
                , centerY
                , scrollbarY
                , width fill
                , UI.fontSize.large
                ]
            <|
                column
                    [ UI.spacing.small
                    , centerX
                    , width (fill |> maximum (ViewportSize.width viewportSize * 3 // 4))
                    , UI.paddingVertical.veryLarge
                    ]
                <|
                    [ column
                        [ testid "welcome-text"
                        , Font.center
                        , centerX
                        , UI.spacing.small
                        ]
                        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ]
                            [ text "Welcome!" ]
                        , paragraph []
                            [ text "This is a "
                            , UI.viewWebResourceLink [] palette WebResource.PLLExplanation "PLL"
                            , text " trainer which attempts to remove both the manual scrambling to create more flow, and to make practice closer to real life by timing from "
                            , UI.viewWebResourceLink [] palette WebResource.HomeGripExplanation "home grip"
                            , text
                                ", and including recognition and pre- and post-"
                            , UI.viewWebResourceLink [] palette WebResource.AUFExplanation "AUF"
                            , text
                                " in timing. Many improvements including intelligently displaying your weakest cases to enhance learning are planned!"
                            ]
                        ]
                    , UI.viewDivider palette
                    , paragraph
                        [ UI.fontSize.veryLarge
                        , centerX
                        , Font.center
                        , testid "cube-start-explanation"
                        , Region.heading 1
                        ]
                      <|
                        [ text "Orient Solved Cube Like This:" ]
                    , el [ centerX ] <|
                        ViewCube.uFRWithLetters
                            [ htmlTestid "cube-start-state" ]
                            200
                            Cube.solved
                    , PLLTrainer.ButtonWithShortcut.view
                        hardwareAvailable
                        [ testid "start-button"
                        , centerX
                        ]
                        { onPress = Just transitions.startTest
                        , labelText = "Start"
                        , color = palette.primary
                        , keyboardShortcut = Key.Space
                        }
                        UI.viewButton.large
                    , UI.viewDivider palette
                    , column
                        [ testid "instructions-text"
                        , Font.center
                        , centerX
                        , UI.spacing.small
                        ]
                        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ] [ text "Instructions:" ]
                        , paragraph []
                            [ text "When you press the start button (or space) you will have a second to get your cube in "
                            , UI.viewWebResourceLink
                                []
                                palette
                                WebResource.HomeGripExplanation
                                "home grip"
                            , text ". Then a "
                            , UI.viewWebResourceLink
                                []
                                palette
                                WebResource.PLLExplanation
                                "PLL"
                            , text " case will show up and the timer will start. If you successfully recognize the case apply the moves to your cube that would solve the cube on screen (including pre- and post-"
                            , UI.viewWebResourceLink
                                []
                                palette
                                WebResource.AUFExplanation
                                "AUF"
                            , text
                                "), and then press anything to stop the timer. If you don't recognize the case just press anything when you are sure you can't recall it. Things to press include any keyboard key, the screen and your mouse/touchpad."
                            ]
                        , paragraph []
                            [ text "You will then be displayed how the cube should look if you applied the correct moves. Click the button labelled correct or wrong depending on whether your cube matches the one on screen, and if you got it correct, simply continue to the next case without any change to your cube!"
                            ]
                        , paragraph []
                            [ text "If you got it wrong you will have to solve the cube to reset it before being able to continue to the next case. Don't worry, you will be instructed through all this by the application."
                            ]
                        ]
                    , UI.viewDivider palette
                    , column
                        [ testid "learning-resources"
                        , centerX
                        , UI.spacing.small
                        ]
                        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1, Font.center ] [ text "Learning Resources:" ]
                        , UI.viewUnorderedList [ centerX ]
                            [ paragraph []
                                [ UI.viewWebResourceLink
                                    []
                                    palette
                                    WebResource.TwoSidedPllRecognitionGuide
                                    "Two Sided PLL Recognition Guide"
                                ]
                            , paragraph []
                                [ UI.viewWebResourceLink
                                    []
                                    palette
                                    WebResource.PLLAlgorithmsResource
                                    "Fast PLL Algorithms And Finger Tricks"
                                ]
                            , paragraph []
                                [ text "And just generally make sure you drill you algorithms until you can do them without looking!" ]
                            ]
                        ]
                    ]
    }
