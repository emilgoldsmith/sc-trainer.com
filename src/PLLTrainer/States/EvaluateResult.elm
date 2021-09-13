module PLLTrainer.States.EvaluateResult exposing (Arguments, Model, Msg, Transitions, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Json.Decode
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.Subscription
import Shared
import TimeInterval exposing (TimeInterval)
import UI
import View
import ViewCube
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> Transitions msg -> Arguments -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state { viewportSize, palette, hardwareAvailable } transitions arguments toMsg =
    PLLTrainer.State.element
        { init = init
        , view = view viewportSize palette hardwareAvailable transitions arguments
        , subscriptions = subscriptions transitions arguments toMsg
        , update = update
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { expectedCubeState : Cube
    , result : TimeInterval
    , transitionsDisabled : Bool
    }


type alias Transitions msg =
    { evaluateCorrect : msg
    , evaluateWrong : msg
    , noOp : msg
    }



-- INIT


type alias Model =
    { spacePressStarted : Bool
    , wPressStarted : Bool
    }


init : ( Model, Cmd msg )
init =
    ( { spacePressStarted = False, wPressStarted = False }, Cmd.none )



-- UPDATE


type Msg
    = SpaceStarted
    | WStarted


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        SpaceStarted ->
            ( { model | spacePressStarted = True }, Cmd.none )

        WStarted ->
            ( { model | wPressStarted = True }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Transitions msg -> Arguments -> (Msg -> msg) -> Model -> PLLTrainer.Subscription.Subscription msg
subscriptions transitions arguments toMsg model =
    PLLTrainer.Subscription.onlyBrowserEvents <|
        if arguments.transitionsDisabled then
            Sub.none

        else
            Sub.batch
                [ Browser.Events.onKeyDown <|
                    Json.Decode.map
                        (\key ->
                            case key of
                                Key.Space ->
                                    toMsg SpaceStarted

                                Key.W ->
                                    toMsg WStarted

                                _ ->
                                    transitions.noOp
                        )
                        Key.decodeNonRepeatedKeyEvent
                , Browser.Events.onKeyUp <|
                    Json.Decode.map
                        (\key ->
                            case key of
                                Key.Space ->
                                    if model.spacePressStarted then
                                        transitions.evaluateCorrect

                                    else
                                        transitions.noOp

                                Key.W ->
                                    if model.wPressStarted then
                                        transitions.evaluateWrong

                                    else
                                        transitions.noOp

                                _ ->
                                    transitions.noOp
                        )
                        Key.decodeNonRepeatedKeyEvent
                ]



-- VIEW


view : ViewportSize -> UI.Palette -> Shared.HardwareAvailable -> Transitions msg -> Arguments -> Model -> PLLTrainer.State.View msg
view viewportSize palette hardwareAvailable transitions arguments _ =
    { overlays = View.buildOverlays []
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
                    [ ViewCube.view [ htmlTestid "expected-cube-front" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ufrDisplayAngle
                        , annotateFaces = True
                        }
                        arguments.expectedCubeState
                    , ViewCube.view [ htmlTestid "expected-cube-back" ]
                        { pixelSize = cubeSize
                        , displayAngle = Cube.ublDisplayAngle
                        , annotateFaces = True
                        }
                        arguments.expectedCubeState
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
