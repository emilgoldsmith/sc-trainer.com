module PLLTrainer.States.PickTargetParametersPage exposing (Model, Msg, Transitions, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Input as Input
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
                transitions
                toMsg
        , update = update
        , nonRepeatedKeyUpHandler = Nothing
        }



-- TRANSITIONS


type alias Transitions msg =
    { submit : msg
    }



-- INIT


type alias Model =
    { targetRecognitionTimeInSeconds : Float
    , targetTps : Float
    }


init : Shared.Model -> Model
init shared =
    let
        targetParameters =
            User.getPLLTargetParameters shared.user
    in
    { targetRecognitionTimeInSeconds = targetParameters.recognitionTimeInSeconds
    , targetTps = targetParameters.tps
    }



-- UPDATE


type Msg
    = Msg


update : Msg -> Model -> Model
update msg model =
    model



-- VIEW


view :
    Transitions msg
    -> (Msg -> msg)
    -> Model
    -> PLLTrainer.State.View msg
view transitions toMsg model =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "pick-target-parameters-container"
                , centerX
                , centerY
                ]
                [ paragraph [ testid "explanation" ] [ text "These are the target parameters" ]
                , el [ testid "recognition-time-input" ] <|
                    Input.slider
                        [ width (px 100)
                        , height (px 30)
                        ]
                        { onChange = always (toMsg Msg)
                        , label = Input.labelAbove [] (text "label")
                        , min = 0.1
                        , max = 5
                        , value = 2
                        , thumb = Input.defaultThumb
                        , step = Nothing
                        }
                , el [ testid "target-TPS-input" ] <|
                    Input.slider
                        [ width (px 100)
                        , height (px 30)
                        ]
                        { onChange = always (toMsg Msg)
                        , label = Input.labelAbove [] (text "label")
                        , min = 0.1
                        , max = 5
                        , value = 2
                        , thumb = Input.defaultThumb
                        , step = Nothing
                        }
                , UI.viewButton.large [ testid "submit-button" ]
                    { onPress = Nothing
                    , color = rgb255 150 150 150
                    , label = always (text "label")
                    }
                ]
    }
