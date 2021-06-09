module PLLTrainer.States.PickAlgorithmPage exposing (Model, Msg, state)

import Algorithm exposing (Algorithm)
import Css exposing (testid)
import Element exposing (..)
import Element.Input as Input
import Html.Events
import Json.Decode
import Key
import PLL
import PLLTrainer.State
import PLLTrainer.Subscription
import Shared
import Task
import View


state : Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state _ transitions toMsg =
    PLLTrainer.State.element
        { init = init
        , update = update transitions
        , subscriptions = subscriptions
        , view = view toMsg
        }



-- TRANSITIONS


type alias Transitions msg =
    { continue : Algorithm -> msg
    }



-- INIT


type Model
    = InputNotInteractedWith
    | ValidAlgorithm String Algorithm
    | InvalidAlgorithm { text : String, errorMessage : String }


init : ( Model, Cmd msg )
init =
    ( InputNotInteractedWith, Cmd.none )



-- MODEL HELPERS


getInputText : Model -> String
getInputText model =
    case model of
        InputNotInteractedWith ->
            ""

        ValidAlgorithm text _ ->
            text

        InvalidAlgorithm { text } ->
            text


getAlgorithm : Model -> Maybe Algorithm
getAlgorithm model =
    case model of
        InputNotInteractedWith ->
            Nothing

        ValidAlgorithm _ algorithm ->
            Just algorithm

        InvalidAlgorithm _ ->
            Nothing


getError : Model -> Maybe String
getError model =
    case model of
        InputNotInteractedWith ->
            Nothing

        ValidAlgorithm _ _ ->
            Nothing

        InvalidAlgorithm { errorMessage } ->
            Just errorMessage



-- UPDATE


type Msg
    = UpdateAlgorithmString String
    | Submit


update : Transitions msg -> Msg -> Model -> ( Model, Cmd msg )
update transitions msg model =
    case msg of
        UpdateAlgorithmString algorithmString ->
            let
                algorithmResult =
                    Algorithm.fromString algorithmString

                newModel =
                    algorithmResult
                        |> Result.map (ValidAlgorithm algorithmString)
                        |> Result.withDefault
                            (InvalidAlgorithm
                                { text = algorithmString
                                , errorMessage = "error"
                                }
                            )
            in
            ( newModel, Cmd.none )

        Submit ->
            case model of
                InputNotInteractedWith ->
                    ( InvalidAlgorithm { text = "", errorMessage = "error" }
                    , Cmd.none
                    )

                InvalidAlgorithm _ ->
                    ( model, Cmd.none )

                ValidAlgorithm _ _ ->
                    ( model
                    , Task.perform
                        transitions.continue
                        (Task.succeed
                            (PLL.getAlgorithm PLL.referenceAlgorithms PLL.H)
                        )
                    )



-- SUBSCRIPTIONS


subscriptions : Model -> PLLTrainer.Subscription.Subscription msg
subscriptions _ =
    PLLTrainer.Subscription.none



-- VIEW


view : (Msg -> msg) -> Model -> PLLTrainer.State.View msg
view toMsg model =
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
                        , onEnter (toMsg Submit)
                        ]
                        { onChange = toMsg << UpdateAlgorithmString
                        , text = getInputText model
                        , placeholder = Nothing
                        , label = Input.labelAbove [] none
                        }
                    , Maybe.map
                        (\error -> el [ testid "error-message" ] <| text error)
                        (getError model)
                        |> Maybe.withDefault none
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
