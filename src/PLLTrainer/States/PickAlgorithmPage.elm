module PLLTrainer.States.PickAlgorithmPage exposing (Arguments, Model, Msg, state)

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
import PLLTrainer.TestCase
import Ports
import Shared
import Task
import View


state : Arguments -> Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state { currentTestCase } _ transitions toMsg =
    PLLTrainer.State.element
        { init = init toMsg
        , update = update transitions currentTestCase
        , subscriptions = subscriptions
        , view = view toMsg
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { currentTestCase : PLLTrainer.TestCase.TestCase
    }


type alias Transitions msg =
    { continue : Algorithm -> msg
    }



-- INIT


type alias Model =
    { text : String
    , error : Maybe Error
    }


type Error
    = AlgorithmParsingError Algorithm.FromStringError
    | DoesntSolveCaseError


focusOnLoadId : String
focusOnLoadId =
    "focus-on-load"


init : (Msg -> msg) -> ( Model, Cmd msg )
init toMsg =
    ( { text = "", error = Nothing }
    , Task.attempt
        (toMsg << FocusAttempted)
        (Browser.Dom.focus focusOnLoadId)
    )



-- UPDATE


type Msg
    = UpdateText String
    | Submit
    | FocusAttempted (Result Browser.Dom.Error ())


update :
    Transitions msg
    -> PLLTrainer.TestCase.TestCase
    -> Msg
    -> Model
    -> ( Model, Cmd msg )
update transitions currentTestCase msg model =
    case msg of
        UpdateText newText ->
            ( { model | text = newText }, Cmd.none )

        Submit ->
            case Algorithm.fromString model.text of
                Err parsingError ->
                    ( { model | error = Just (AlgorithmParsingError parsingError) }, Cmd.none )

                Ok algorithm ->
                    if
                        PLL.solvedBy
                            algorithm
                            (PLLTrainer.TestCase.pll currentTestCase)
                    then
                        ( model
                        , Task.perform
                            transitions.continue
                            (Task.succeed <|
                                PLL.getAlgorithm PLL.referenceAlgorithms PLL.H
                            )
                        )

                    else
                        ( { model | error = Just DoesntSolveCaseError }, Cmd.none )

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
                        { onChange = toMsg << UpdateText
                        , text = model.text
                        , placeholder = Nothing
                        , label = Input.labelAbove [] none
                        }
                    , maybeViewError model.error
                    ]
    }


maybeViewError : Maybe Error -> Element msg
maybeViewError maybeError =
    Maybe.map viewError maybeError |> Maybe.withDefault none


viewError : Error -> Element msg
viewError error =
    case error of
        AlgorithmParsingError parsingError ->
            viewParsingError parsingError

        DoesntSolveCaseError ->
            viewDoesntMatchCaseError


viewDoesntMatchCaseError : Element msg
viewDoesntMatchCaseError =
    el [ testid "algorithm-doesnt-match-case", errorMessageTestType ] <|
        text "algorithm doesn't match the case"


viewParsingError : Algorithm.FromStringError -> Element msg
viewParsingError error =
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

        Algorithm.SpansOverSeveralLines _ ->
            el
                [ errorMessageTestType
                ]
            <|
                text "Congratulations! You somehow managed to make your algorithm span several lines of text which is not allowed and the input shouldn't even let you do. If you want to proceed you should undo it though :)"

        Algorithm.UnexpectedError _ ->
            el [ errorMessageTestType ] <|
                text "Congratulations! You somehow managed to make our algorithm parser error in a way we had never expected to happen. If you're online a simple error description (with no personal data) has already been sent to the developers so hopefully this will soon be fixed, but thanks for helping find our edge cases! Until then see if you can figure out the problem with your algorithm yourself, or maybe try out writing it from scratch again"


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
