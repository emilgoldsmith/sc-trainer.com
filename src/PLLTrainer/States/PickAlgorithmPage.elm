module PLLTrainer.States.PickAlgorithmPage exposing (Model, Msg, state)

import Css exposing (testid)
import Element exposing (..)
import Element.Input as Input
import Html.Events
import Json.Decode
import Key
import PLLTrainer.State
import PLLTrainer.Subscription
import Shared
import View


state : Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state _ transitions toMsg =
    PLLTrainer.State.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view toMsg transitions
        }



-- TRANSITIONS


type alias Transitions msg =
    { continue : msg
    }



-- INIT


type alias Model =
    { algorithmString : String
    }


init : ( Model, Cmd msg )
init =
    ( { algorithmString = "" }, Cmd.none )



-- UPDATE


type Msg
    = UpdateAlgorithmString String


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        UpdateAlgorithmString newAlgorithmString ->
            ( { model | algorithmString = newAlgorithmString }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> PLLTrainer.Subscription.Subscription msg
subscriptions _ =
    PLLTrainer.Subscription.none



-- VIEW


view : (Msg -> msg) -> Transitions msg -> Model -> PLLTrainer.State.View msg
view toMsg transitions model =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            el
                [ testid "pick-algorithm-container"
                , centerX
                , centerY
                ]
            <|
                column []
                    [ Input.text
                        [ testid "algorithm-input"
                        , onEnter transitions.continue
                        ]
                        { onChange = toMsg << UpdateAlgorithmString
                        , text = model.algorithmString
                        , placeholder = Nothing
                        , label = Input.labelAbove [] none
                        }
                    ]
    }


onEnter : msg -> Attribute msg
onEnter msg =
    htmlAttribute
        (Html.Events.on "keyup"
            (Key.decodeNonRepeatedKeyEvent
                |> Json.Decode.andThen
                    (\key ->
                        if key == Key.Enter then
                            Json.Decode.succeed msg

                        else
                            Json.Decode.fail "Not the enter key"
                    )
            )
        )
