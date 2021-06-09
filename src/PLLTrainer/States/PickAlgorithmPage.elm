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
    { continue : Algorithm -> msg
    }



-- INIT


type Model
    = InputNotInteractedWith
    | ValidAlgorithm String Algorithm
    | InvalidAlgorithm String


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

        InvalidAlgorithm text ->
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



-- UPDATE


type Msg
    = UpdateAlgorithmString String


update : Msg -> Model -> ( Model, Cmd msg )
update msg _ =
    case msg of
        UpdateAlgorithmString algorithmString ->
            let
                algorithmResult =
                    Algorithm.fromString algorithmString

                newModel =
                    algorithmResult
                        |> Result.map (ValidAlgorithm algorithmString)
                        |> Result.withDefault (InvalidAlgorithm algorithmString)
            in
            ( newModel, Cmd.none )



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
                    [ let
                        maybeOnEnterAttribute =
                            getAlgorithm model
                                |> Maybe.map (\algorithm -> [ onEnter (transitions.continue (PLL.getAlgorithm PLL.referenceAlgorithms PLL.H)) ])
                                |> Maybe.withDefault []
                      in
                      Input.text
                        (testid "algorithm-input"
                            :: maybeOnEnterAttribute
                        )
                        { onChange = toMsg << UpdateAlgorithmString
                        , text = getInputText model
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
