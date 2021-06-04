module PLLTrainer.States.EvaluateResult exposing (Arguments, Transitions, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
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


state : Shared.Model -> Transitions msg -> Arguments -> { view : StatefulPage.StateView msg, subscriptions : Sub msg }
state { viewportSize, palette, hardwareAvailable } transitions arguments =
    { view = view viewportSize palette hardwareAvailable transitions arguments
    , subscriptions = subscriptions transitions
    }


type alias Transitions msg =
    { evaluateCorrect : msg
    , evaluateWrong : msg
    , noOp : msg
    }


type alias Arguments =
    { expectedCubeState : Cube
    , result : TimeInterval
    , transitionsDisabled : Bool
    }


subscriptions : Transitions msg -> Sub msg
subscriptions transitions =
    Browser.Events.onKeyUp <|
        Json.Decode.map
            (\key ->
                case key of
                    Key.Space ->
                        transitions.evaluateCorrect

                    Key.W ->
                        transitions.evaluateWrong

                    _ ->
                        transitions.noOp
            )
            Key.decodeNonRepeatedKeyEvent


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> Arguments -> StatefulPage.StateView msg
view viewportSize palette hardwareAvailable transitions arguments =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            let
                overallPadding =
                    ViewportSize.minDimension viewportSize // 20

                cubeSize =
                    ViewportSize.minDimension viewportSize // 3

                cubeSpacing =
                    ViewportSize.minDimension viewportSize // 15

                timerSize =
                    ViewportSize.minDimension viewportSize // 6

                buttonSpacing =
                    ViewportSize.minDimension viewportSize // 15

                button =
                    \attributes ->
                        UI.viewButton.customSize (ViewportSize.minDimension viewportSize // 13)
                            (attributes
                                ++ [ Font.center
                                   , width (px <| ViewportSize.minDimension viewportSize // 3)
                                   ]
                            )
            in
            column
                [ testid "evaluate-test-result-container"
                , centerX
                , centerY
                , height (fill |> maximum (ViewportSize.minDimension viewportSize))
                , spaceEvenly
                , padding overallPadding
                ]
                [ el
                    [ testid "time-result"
                    , centerX
                    , Font.size timerSize
                    ]
                  <|
                    text <|
                        TimeInterval.displayTwoDecimals arguments.result
                , row
                    [ centerX
                    , spacing cubeSpacing
                    ]
                    [ ViewCube.uFRWithLetters [ htmlTestid "expected-cube-front" ] cubeSize arguments.expectedCubeState
                    , ViewCube.uBLWithLetters [ htmlTestid "expected-cube-back" ] cubeSize arguments.expectedCubeState
                    ]
                , row [ centerX, spacing buttonSpacing ]
                    [ PLLTrainer.ButtonWithShortcut.view
                        hardwareAvailable
                        [ testid "correct-button"
                        ]
                        { onPress =
                            if arguments.transitionsDisabled then
                                Nothing

                            else
                                Just transitions.evaluateCorrect
                        , labelText = "Correct"
                        , color = palette.correct
                        , keyboardShortcut = Key.Space
                        }
                        button
                    , PLLTrainer.ButtonWithShortcut.view
                        hardwareAvailable
                        [ testid "wrong-button"
                        ]
                        { onPress =
                            if arguments.transitionsDisabled then
                                Nothing

                            else
                                Just transitions.evaluateWrong
                        , labelText = "Wrong"
                        , keyboardShortcut = Key.W
                        , color = palette.wrong
                        }
                        button
                    ]
                ]
    }
