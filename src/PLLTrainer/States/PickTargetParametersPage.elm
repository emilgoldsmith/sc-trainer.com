module PLLTrainer.States.PickTargetParametersPage exposing (Model, Msg, Transitions, state)

import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Key
import PLLTrainer.State
import Shared
import UI
import User
import View


state : Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state shared transitions toMsg =
    PLLTrainer.State.sandbox
        { init = init shared
        , view =
            view
                shared
                transitions
                toMsg
        , update = update
        , nonRepeatedKeyUpHandler = Nothing
        }



-- TRANSITIONS


type alias Transitions msg =
    { submit :
        { newTargetRecognitionTime : Float
        , newTargetTps : Float
        }
        -> msg
    }



-- INIT


type alias Model =
    { targetRecognitionTimeInSeconds : String
    , targetTps : String
    }


init : Shared.Model -> Model
init shared =
    let
        targetParameters =
            User.getPLLTargetParameters shared.user
    in
    { targetRecognitionTimeInSeconds = String.fromFloat targetParameters.recognitionTimeInSeconds
    , targetTps = String.fromFloat targetParameters.tps
    }



-- UPDATE


type Msg
    = UpdateRecognitionTime String
    | UpdateTPS String
    | NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateRecognitionTime nextRecognitionTime ->
            { model | targetRecognitionTimeInSeconds = processFloatStringInput nextRecognitionTime }

        UpdateTPS nextTPS ->
            { model | targetTps = processFloatStringInput nextTPS }

        NoOp ->
            model


processFloatStringInput : String -> String
processFloatStringInput =
    String.map
        (\character ->
            case character of
                ',' ->
                    '.'

                x ->
                    x
        )



-- VIEW


view :
    Shared.Model
    -> Transitions msg
    -> (Msg -> msg)
    -> Model
    -> PLLTrainer.State.View msg
view shared transitions toMsg model =
    { overlays = View.buildOverlays []
    , body =
        let
            submitMsg =
                Maybe.map2
                    (\recognition tps ->
                        Just <|
                            transitions.submit
                                { newTargetRecognitionTime = recognition
                                , newTargetTps = tps
                                }
                    )
                    (String.toFloat model.targetRecognitionTimeInSeconds)
                    (String.toFloat model.targetTps)
                    |> Maybe.withDefault (Just <| toMsg NoOp)
        in
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                el
                    [ testid "pick-target-parameters-container"
                    , htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , width fill
                    , height fill
                    , scrollbarY
                    ]
                <|
                    column
                        [ centerX
                        , centerY
                        , width (fill |> maximum 700)
                        , UI.fontSize.large
                        , UI.spacingVertical.medium
                        , UI.paddingAll.veryLarge
                        ]
                        [ textColumn [ testid "explanation", UI.spacingVertical.small, width fill ]
                            [ paragraph []
                                [ text "Welcome! It is different from person to person how fast they expect to solve a case before they consider it learned."
                                , text " That's why we ask you to specify your expectations here before we get started. Don't worry if this seems confusing,"
                                , text " in that case just leave the values as they are right now, as this is a sensible default we have provided for you that"
                                , text " should work well for everyone, and especially less experienced cubers."
                                ]
                            , paragraph []
                                [ text "If you decide to change the values, you should note that they are not meant to signify your ultimate speed goals, but rather"
                                , text " the point when you are no longer stumbling through the algorithm. However, when at this point you should be recognizing the case"
                                , text " comfortably even if still a bit slowly, and executing it without any significant pauses. If these values are set too low the"
                                , text " app could take too long to move onto new algorithms and mark it as learned, and it is therefore recommended to keep them"
                                , text " on the higher side of what you may think you want."
                                ]
                            , paragraph []
                                [ text "Recognition time is the time taken in seconds from seeing the cube to executing the first move. TPS is how many turns per second"
                                , text " you are executing the algorithm itself at after the recognition time."
                                ]
                            ]
                        , targetFloatInput
                            { testId = "recognition-time-input"
                            , errorTestId = "recognition-time-error"
                            , onChange = toMsg << UpdateRecognitionTime
                            , onEnter = submitMsg
                            , inputContent = model.targetRecognitionTimeInSeconds
                            , label = "Recognition Time"
                            , palette = shared.palette
                            , unit = "s"
                            , unitWidth = 10.5
                            , maxExpectedMainDigits = 1
                            }
                        , targetFloatInput
                            { testId = "target-TPS-input"
                            , errorTestId = "tps-error"
                            , onChange = toMsg << UpdateTPS
                            , onEnter = submitMsg
                            , inputContent = model.targetTps
                            , label = "TPS"
                            , palette = shared.palette
                            , unit = "tps"
                            , unitWidth = 28.0667
                            , maxExpectedMainDigits = 2
                            }
                        , UI.viewButton.large [ testid "submit-button", centerX ]
                            { color = shared.palette.primaryButton
                            , label = always (text "Submit")
                            , onPress = submitMsg
                            }
                        ]
            )
    }


targetFloatInput :
    { testId : String
    , errorTestId : String
    , onChange : String -> msg
    , onEnter : Maybe msg
    , inputContent : String
    , label : String
    , palette : UI.Palette
    , unit : String
    , unitWidth : Float
    , maxExpectedMainDigits : Int
    }
    -> Element msg
targetFloatInput params =
    let
        { maybeExtraErrorStyling, maybeErrorText } =
            case String.toFloat params.inputContent of
                Just _ ->
                    { maybeExtraErrorStyling = []
                    , maybeErrorText = none
                    }

                Nothing ->
                    { maybeExtraErrorStyling =
                        [ Border.glow params.palette.error 3 ]
                    , maybeErrorText =
                        el [ testid params.errorTestId, errorMessageTestType, Font.color params.palette.error ] <|
                            text "Invalid Number"
                    }

        maybeOnEnterAttribute =
            case params.onEnter of
                Just msg ->
                    [ Key.onEnter msg ]

                Nothing ->
                    []
    in
    column
        [ centerX
        , UI.spacingVertical.extremelySmall
        ]
        [ Input.text
            (maybeExtraErrorStyling
                ++ maybeOnEnterAttribute
                ++ [ testid params.testId
                   , htmlAttribute <| Html.Attributes.attribute "inputmode" "decimal"
                   , width <| px (45 + 10 * params.maxExpectedMainDigits + round params.unitWidth)
                   , onRight <|
                        el [ moveDown 10, moveLeft (4 + params.unitWidth), Font.color params.palette.label ] <|
                            text params.unit
                   , paddingEach { left = 12, right = 5 + round params.unitWidth, top = 11, bottom = 11 }
                   , centerX
                   ]
            )
            { onChange = params.onChange
            , text = params.inputContent
            , placeholder = Nothing
            , label = Input.labelAbove [ Font.color params.palette.label, centerX ] <| text params.label
            }
        , maybeErrorText
        ]
