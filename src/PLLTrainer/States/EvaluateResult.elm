module PLLTrainer.States.EvaluateResult exposing (Arguments, Model, Msg, Transitions, state)

import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube exposing (Cube)
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import Json.Decode
import Key
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.Subscription
import Shared
import TimeInterval exposing (TimeInterval)
import UI
import User
import View
import ViewCube
import ViewportSize


state : Shared.Model -> Transitions msg -> Arguments -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state shared transitions arguments toMsg =
    PLLTrainer.State.element
        { init = init
        , view = view shared transitions arguments
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


view : Shared.Model -> Transitions msg -> Arguments -> Model -> PLLTrainer.State.View msg
view shared transitions arguments _ =
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                let
                    overallPadding =
                        ViewportSize.minDimension shared.viewportSize // 20

                    cubeSize =
                        ViewportSize.minDimension shared.viewportSize // 3

                    cubeSpacing =
                        ViewportSize.minDimension shared.viewportSize // 15

                    timerSize =
                        ViewportSize.minDimension shared.viewportSize // 6

                    buttonSpacing =
                        ViewportSize.minDimension shared.viewportSize // 15

                    button =
                        \attributes ->
                            UI.viewButton.customSize (ViewportSize.minDimension shared.viewportSize // 13)
                                (attributes
                                    ++ [ Font.center
                                       , width (px <| ViewportSize.minDimension shared.viewportSize // 3)
                                       ]
                                )
                in
                column
                    [ testid "evaluate-test-result-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , centerX
                    , centerY
                    , height (fill |> maximum (ViewportSize.minDimension shared.viewportSize))
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
                        [ ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "expected-cube-front" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            arguments.expectedCubeState
                        , ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "expected-cube-back" ]
                            { pixelSize = cubeSize
                            , displayAngle = Cube.ublDisplayAngle
                            , annotateFaces = True
                            , theme = User.cubeTheme shared.user
                            }
                            arguments.expectedCubeState
                        ]
                    , row [ centerX, spacing buttonSpacing ]
                        [ PLLTrainer.ButtonWithShortcut.view
                            shared.hardwareAvailable
                            [ testid "correct-button"
                            ]
                            shared.palette
                            { onPress =
                                if arguments.transitionsDisabled then
                                    Nothing

                                else
                                    Just transitions.evaluateCorrect
                            , labelText = "Correct"
                            , color = shared.palette.correct
                            , keyboardShortcut = Key.Space
                            , disabledStyling = False
                            }
                            button
                        , PLLTrainer.ButtonWithShortcut.view
                            shared.hardwareAvailable
                            [ testid "wrong-button"
                            ]
                            shared.palette
                            { onPress =
                                if arguments.transitionsDisabled then
                                    Nothing

                                else
                                    Just transitions.evaluateWrong
                            , labelText = "Wrong"
                            , keyboardShortcut = Key.W
                            , color = shared.palette.wrong
                            , disabledStyling = False
                            }
                            button
                        ]
                    ]
            )
    }
