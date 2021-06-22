module PLLTrainer.States.PickAlgorithmPage exposing (Arguments, Model, Msg, state)

import Algorithm exposing (Algorithm, FromStringError(..))
import Browser.Dom
import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Attributes
import Html.Events
import Json.Decode
import Key
import PLL
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.Subscription
import PLLTrainer.TestCase
import Ports
import Shared
import Task
import UI
import View


state : Arguments -> Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state { currentTestCase } shared transitions toMsg =
    PLLTrainer.State.element
        { init = init toMsg
        , update = update transitions currentTestCase
        , subscriptions = subscriptions
        , view = view currentTestCase toMsg shared
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
                    let
                        command =
                            case parsingError of
                                UnexpectedError { inputString, errorIndex, debugInfo } ->
                                    Ports.logError
                                        ("Unexpected error occurred in parsing an algorithm. The debug info was `"
                                            ++ debugInfo
                                            ++ "` and the error occurred at index "
                                            ++ String.fromInt errorIndex
                                            ++ " in the following string: "
                                            ++ inputString
                                        )

                                _ ->
                                    Cmd.none
                    in
                    ( { model | error = Just (AlgorithmParsingError parsingError) }, command )

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


view : PLLTrainer.TestCase.TestCase -> (Msg -> msg) -> Shared.Model -> Model -> PLLTrainer.State.View msg
view currentTestCase toMsg shared model =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            column
                [ testid "pick-algorithm-container"
                , centerX
                , centerY
                , UI.spacing.large
                , UI.paddingHorizontal.large
                ]
                [ column
                    [ testid "explanation-text"
                    , centerX
                    , Font.center
                    , UI.spacing.verySmall
                    ]
                    [ paragraph
                        [ UI.fontSize.veryLarge
                        , Region.heading 1
                        ]
                        [ text
                            ("Pick Algorithm For "
                                ++ PLL.getLetters (PLLTrainer.TestCase.pll currentTestCase)
                            )
                        ]
                    , paragraph
                        [ UI.fontSize.medium
                        ]
                        [ text "We use this to correctly identify which AUFs you need to do for each case"
                        ]
                    ]
                , column
                    [ centerX
                    , UI.spacing.verySmall
                    ]
                    [ Input.text
                        [ testid "algorithm-input"
                        , onEnter (toMsg Submit)
                        , htmlAttribute <| Html.Attributes.id focusOnLoadId
                        , centerX
                        ]
                        { onChange = toMsg << UpdateText
                        , text = model.text
                        , placeholder = Nothing
                        , label = Input.labelAbove [] none
                        }
                    , maybeViewError shared.palette model.error
                    ]
                , PLLTrainer.ButtonWithShortcut.view
                    shared.hardwareAvailable
                    [ testid "submit-button"
                    , centerX
                    ]
                    { onPress = Just (toMsg Submit)
                    , labelText = "Submit"
                    , color = shared.palette.primary
                    , keyboardShortcut = Key.Enter
                    }
                    UI.viewButton.large
                ]
    }


maybeViewError : UI.Palette -> Maybe Error -> Element msg
maybeViewError palette maybeError =
    Maybe.map (viewError palette) maybeError |> Maybe.withDefault none


viewError : UI.Palette -> Error -> Element msg
viewError palette error =
    case error of
        AlgorithmParsingError parsingError ->
            viewParsingError palette parsingError

        DoesntSolveCaseError ->
            viewDoesntMatchCaseError


viewDoesntMatchCaseError : Element msg
viewDoesntMatchCaseError =
    el [ testid "algorithm-doesnt-match-case", errorMessageTestType ] <|
        text "algorithm doesn't match the case"


viewParsingError : UI.Palette -> Algorithm.FromStringError -> Element msg
viewParsingError palette error =
    let
        sharedErrorAttributes =
            [ errorMessageTestType
            , Font.color palette.errorText
            , UI.fontSize.medium
            , UI.spacing.verySmall
            , Font.center
            , width fill
            ]
    in
    case error of
        Algorithm.EmptyAlgorithm ->
            el (testid "input-required" :: sharedErrorAttributes) <| text "input required"

        Algorithm.InvalidTurnable { inputString, invalidTurnable, errorIndex } ->
            column
                (testid "invalid-turnable" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "The turnable "
                    , el [ Font.bold ] <| text invalidTurnable
                    , text " is invalid. We expected something like U, Rw, r, x or M:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + String.length invalidTurnable)
                ]

        Algorithm.InvalidTurnLength { inputString, invalidLength, errorIndex } ->
            column
                (testid "invalid-turn-length" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "The turn length "
                    , el [ Font.bold ] <| text invalidLength
                    , text " is invalid. Only lengths allowed are 2 and 3:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + String.length invalidLength)
                ]

        Algorithm.RepeatedTurnable { inputString, errorIndex } ->
            column
                (testid "repeated-turnable" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "You repeated a turnable twice in a row. Try combining the two into one, such as U2 U becoming U':"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.WideMoveStylesMixed { inputString, errorIndex, invalidWideMove } ->
            column
                (testid "wide-move-styles-mixed" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "You have mixed different types of wide moves. The turnable using a second style was "
                    , el [ Font.bold ] <| text invalidWideMove
                    , text ". To solve this pick one style and use it throughout the algorithm:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + String.length invalidWideMove)
                ]

        Algorithm.TurnWouldWorkWithoutInterruption { inputString, interruptionStart, interruptionEnd } ->
            column
                (testid "turn-would-work-without-interruption" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "An invalid turn was found. The turn would become valid if the underlined interruption was removed:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    interruptionStart
                    interruptionEnd
                ]

        Algorithm.ApostropheWrongSideOfLength { inputString, errorIndex } ->
            column
                (testid "apostrophe-wrong-side-of-length" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "Turn is invalid. It would be valid if you swapped the apostrophe to the other side of the length though:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.UnclosedParenthesis { inputString, openParenthesisIndex } ->
            column
                (testid "unclosed-parenthesis" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "There is an unclosed parenthesis, add a closing parenthesis to fix this:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    openParenthesisIndex
                    (openParenthesisIndex + 1)
                ]

        Algorithm.UnmatchedClosingParenthesis { inputString, errorIndex } ->
            column
                (testid "unmatched-closing-parenthesis" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "There is an unmatched closing parenthesis, remove it or add an opening parenthesis to fix this:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.EmptyParentheses { inputString, errorIndex } ->
            column
                (testid "empty-parentheses" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "There were no turns inside this set of parentheses, remove the parentheses or add some turns inside to fix it:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.NestedParentheses { inputString, errorIndex } ->
            column
                (testid "nested-parentheses" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "There are nested parentheses in this algorithm which is not allowed. Remove them to fix it:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.InvalidSymbol { inputString, errorIndex, symbol } ->
            column
                (testid "invalid-symbol" :: sharedErrorAttributes)
                [ paragraph []
                    [ text "The symbol "
                    , el [ Font.bold ] <| text (String.fromChar symbol)
                    , text " is never valid anywhere in an algorithm, remove it to fix this error:"
                    ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.SpansOverSeveralLines _ ->
            paragraph sharedErrorAttributes
                [ text "Congratulations! You somehow managed to make your algorithm span several lines of text which is not allowed and the input shouldn't even let you do. If you want to proceed you should undo it though :)"
                ]

        Algorithm.UnexpectedError _ ->
            paragraph sharedErrorAttributes
                [ text "Congratulations! You somehow managed to make our algorithm parser error in a way we had never expected to happen. If you're online a simple error description (with no personal data) has already been sent to the developers so hopefully this will soon be fixed, but thanks for helping find our edge cases! Until then see if you can figure out the problem with your algorithm yourself, or maybe try out writing it from scratch again"
                ]


viewUnderlinedPlaceWhereErrorOcurred : String -> Int -> Int -> Element msg
viewUnderlinedPlaceWhereErrorOcurred inputString start end =
    let
        beforeUnderline =
            text (String.left start inputString)

        underlinedCharacters =
            String.toList (String.slice start end inputString)
                |> List.map String.fromChar
                |> List.map
                    (\char ->
                        el [ below (text "~") ] <|
                            text char
                    )

        afterUnderline =
            text (String.dropLeft end inputString)
    in
    row [ centerX ] <|
        beforeUnderline
            :: underlinedCharacters
            ++ [ afterUnderline ]


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
