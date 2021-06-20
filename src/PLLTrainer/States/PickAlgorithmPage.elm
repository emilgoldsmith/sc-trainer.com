module PLLTrainer.States.PickAlgorithmPage exposing (Model, Msg, state)

import Algorithm exposing (Algorithm)
import Browser.Dom
import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Input as Input
import Html.Attributes
import Html.Events
import Json.Decode
import Key
import PLL
import PLLTrainer.State
import PLLTrainer.Subscription
import Ports
import Shared
import Task
import View


state : Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state _ transitions toMsg =
    PLLTrainer.State.element
        { init = init toMsg
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
    | InvalidAlgorithm { text : String, error : Algorithm.FromStringError }


focusOnLoadId : String
focusOnLoadId =
    "focus-on-load"


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    ( InputNotInteractedWith
    , Task.attempt
        (toMsg << FocusAttempted)
        (Browser.Dom.focus focusOnLoadId)
    )



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


getError : Model -> Maybe Algorithm.FromStringError
getError model =
    case model of
        InputNotInteractedWith ->
            Nothing

        ValidAlgorithm _ _ ->
            Nothing

        InvalidAlgorithm { error } ->
            Just error



-- UPDATE


type Msg
    = UpdateAlgorithmString String
    | Submit
    | FocusAttempted (Result Browser.Dom.Error ())


update : Transitions msg -> Msg -> Model -> ( Model, Cmd msg )
update transitions msg model =
    case msg of
        UpdateAlgorithmString "" ->
            ( InvalidAlgorithm { text = "", error = Algorithm.EmptyAlgorithm }
            , Cmd.none
            )

        UpdateAlgorithmString algorithmString ->
            let
                algorithmResult =
                    Algorithm.fromString algorithmString

                newModel =
                    case algorithmResult of
                        Ok algorithm ->
                            ValidAlgorithm algorithmString algorithm

                        Err error ->
                            InvalidAlgorithm
                                { text = algorithmString
                                , error = error
                                }
            in
            ( newModel, Cmd.none )

        Submit ->
            case model of
                InputNotInteractedWith ->
                    ( InvalidAlgorithm { text = "", error = Algorithm.EmptyAlgorithm }
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

        FocusAttempted result ->
            case result of
                Ok _ ->
                    ( model, Cmd.none )

                Err domError ->
                    case domError of
                        Browser.Dom.NotFound idNotFound ->
                            ( model
                            , Ports.logError
                                ("Couldn't find id `"
                                    ++ idNotFound
                                    ++ "` to focus on"
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
                        , htmlAttribute <| Html.Attributes.id focusOnLoadId
                        ]
                        { onChange = toMsg << UpdateAlgorithmString
                        , text = getInputText model
                        , placeholder = Nothing
                        , label = Input.labelAbove [] none
                        }
                    , maybeViewError (getError model)
                    ]
    }


maybeViewError : Maybe Algorithm.FromStringError -> Element msg
maybeViewError maybeError =
    Maybe.map viewError maybeError |> Maybe.withDefault none


viewError : Algorithm.FromStringError -> Element msg
viewError error =
    case error of
        Algorithm.EmptyAlgorithm ->
            el [ testid "input-required", errorMessageTestType ] <| text "input required"

        Algorithm.InvalidTurnable _ ->
            el [ testid "invalid-turnable", errorMessageTestType ] <| text "invalid turnable"

        Algorithm.InvalidTurnLength _ ->
            el [ testid "invalid-turn-length", errorMessageTestType ] <| text "invalid turn length"

        Algorithm.RepeatedTurnable _ ->
            el
                [ testid "repeated-turnable", errorMessageTestType ]
            <|
                text "repeated turnable"

        Algorithm.WideMoveStylesMixed _ ->
            el
                [ testid "wide-move-styles-mixed", errorMessageTestType ]
            <|
                text "wide move styles mixed"

        Algorithm.TurnWouldWorkWithoutInterruption _ ->
            el
                [ testid "turn-would-work-without-interruption", errorMessageTestType ]
            <|
                text
                    "turn would work without interruption"

        Algorithm.ApostropheWrongSideOfLength _ ->
            el
                [ testid "apostrophe-wrong-side-of-length", errorMessageTestType ]
            <|
                text "apostrophe wrong side of length"

        Algorithm.UnclosedParenthesis _ ->
            el
                [ testid "unclosed-parenthesis", errorMessageTestType ]
            <|
                text "unclosed parenthesis"

        Algorithm.UnmatchedClosingParenthesis _ ->
            el
                [ testid "unmatched-closing-parenthesis", errorMessageTestType ]
            <|
                text "unmatched closing parenthesis"

        Algorithm.EmptyParentheses _ ->
            el
                [ testid "empty-parentheses", errorMessageTestType ]
            <|
                text "empty parentheses"

        Algorithm.NestedParentheses _ ->
            el
                [ testid "nested-parentheses"
                , errorMessageTestType
                ]
            <|
                text "nested parentheses"

        Algorithm.InvalidSymbol _ ->
            el
                [ testid "invalid-symbol"
                , errorMessageTestType
                ]
            <|
                text "invalid symbol"

        _ ->
            none


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
