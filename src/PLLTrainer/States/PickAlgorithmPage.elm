module PLLTrainer.States.PickAlgorithmPage exposing (Arguments, Error, Model, Msg, Transitions, cleanUpAlgorithm, state)

import Algorithm exposing (Algorithm, FromStringError(..))
import Browser.Dom
import Browser.Events
import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Attributes
import Json.Decode
import Key
import PLL exposing (PLL)
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.Subscription
import PLLTrainer.TestCase
import Ports
import Shared
import Task
import UI
import User
import View
import WebResource


state : Arguments -> Shared.Model -> Transitions msg -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state { currentTestCase, testCaseResult } shared transitions toMsg =
    PLLTrainer.State.element
        { init = init toMsg
        , update = update transitions currentTestCase
        , subscriptions = subscriptions toMsg transitions
        , view = view currentTestCase testCaseResult toMsg shared
        }



-- ARGUMENTS AND TRANSITIONS


type alias Arguments =
    { currentTestCase : PLLTrainer.TestCase.TestCase
    , testCaseResult : User.TestResult
    }


type alias Transitions msg =
    { continue : Algorithm -> msg
    , noOp : msg
    }



-- INIT


type alias Model =
    { text : String
    , textFromPreviousSubmit : String
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
    ( { text = ""
      , textFromPreviousSubmit = ""
      , error = Nothing
      }
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
                    ( { model | error = Just (AlgorithmParsingError parsingError), textFromPreviousSubmit = model.text }, command )

                Ok algorithm ->
                    let
                        cleanedUpAlgorithm =
                            cleanUpAlgorithm algorithm
                    in
                    if
                        PLL.solvedBy
                            cleanedUpAlgorithm
                            (PLLTrainer.TestCase.pll currentTestCase)
                    then
                        ( model
                        , Task.perform
                            transitions.continue
                            (Task.succeed cleanedUpAlgorithm)
                        )

                    else
                        ( { model | error = Just DoesntSolveCaseError, textFromPreviousSubmit = model.text }, Cmd.none )

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


cleanUpAlgorithm : Algorithm -> Algorithm
cleanUpAlgorithm =
    Algorithm.toTurnList
        >> dropWhile (\(Algorithm.Turn turnable _ _) -> turnable == Algorithm.Y || turnable == Algorithm.Dw || turnable == Algorithm.U)
        >> List.reverse
        -- At the end we just clean up any rotations. There may have been rotations beforehand so we don't actually know if U/Dw are
        -- AUF like moves at this moment given we don't know the rotation of the cube like we do in the beginning
        >> dropWhile (\(Algorithm.Turn turnable _ _) -> turnable == Algorithm.Y || turnable == Algorithm.X || turnable == Algorithm.Z)
        >> List.reverse
        >> Algorithm.fromTurnList


dropWhile : (a -> Bool) -> List a -> List a
dropWhile fn list =
    case list of
        [] ->
            []

        x :: xs ->
            if fn x then
                dropWhile fn xs

            else
                list



-- SUBSCRIPTIONS


subscriptions : (Msg -> msg) -> Transitions msg -> Model -> PLLTrainer.Subscription.Subscription msg
subscriptions toMsg transitions _ =
    PLLTrainer.Subscription.onlyBrowserEvents <|
        Browser.Events.onKeyUp <|
            Json.Decode.map
                (\key ->
                    if key == Key.Enter then
                        toMsg Submit

                    else
                        transitions.noOp
                )
                Key.decodeNonRepeatedKeyEvent



-- VIEW


view :
    PLLTrainer.TestCase.TestCase
    -> User.TestResult
    -> (Msg -> msg)
    -> Shared.Model
    -> Model
    -> PLLTrainer.State.View msg
view currentTestCase testResult toMsg shared model =
    let
        pllCase : PLL
        pllCase =
            PLLTrainer.TestCase.pll currentTestCase

        submitDisabled : Bool
        submitDisabled =
            model.text
                == model.textFromPreviousSubmit
                || String.isEmpty model.text
    in
    { overlays = View.buildOverlays []
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                el
                    [ htmlAttribute <| Html.Attributes.id scrollableContainerId
                    , width fill
                    , height fill
                    , scrollbarY
                    ]
                <|
                    column
                        [ testid "pick-algorithm-container"
                        , centerX
                        , centerY
                        , UI.spacingAll.large
                        , UI.paddingAll.large
                        , width (fill |> maximum 700)
                        , UI.fontSize.medium
                        ]
                        [ textColumn
                            [ testid "explanation-text"
                            , centerX
                            , Font.center
                            , UI.spacingAll.verySmall
                            , width fill
                            ]
                            [ paragraph
                                [ UI.fontSize.veryLarge
                                , Region.heading 1
                                ]
                                [ text
                                    ("Pick "
                                        ++ PLL.getLetters pllCase
                                        ++ "-Perm Algorithm"
                                    )
                                ]
                            , paragraph []
                                [ case testResult of
                                    User.Correct _ ->
                                        el [ testid "correct-text" ] <|
                                            text "Which algorithm did you use?"

                                    User.Wrong _ ->
                                        el [ testid "wrong-text" ] <|
                                            text "Take some time to select which algorithm you'd like to learn for this case and practice it a bit"
                                ]
                            , paragraph []
                                [ text "We use this to correctly identify which AUFs you need to do for each case so we for example can display correct statistics" ]
                            ]
                        , column
                            [ centerX
                            , UI.spacingAll.verySmall
                            , width fill
                            ]
                            [ Input.text
                                [ testid "algorithm-input"
                                , htmlAttribute <| Html.Attributes.id focusOnLoadId
                                , centerX
                                ]
                                { onChange = toMsg << UpdateText
                                , text = model.text
                                , placeholder = Nothing
                                , label = Input.labelHidden "Algorithm Input"
                                }
                            , maybeViewError shared.palette model.error
                            ]
                        , PLLTrainer.ButtonWithShortcut.view
                            shared.hardwareAvailable
                            [ testid "submit-button"
                            , centerX
                            ]
                            shared.palette
                            { onPress = Just (toMsg Submit)
                            , labelText = "Submit"
                            , color = shared.palette.primaryButton
                            , keyboardShortcut = Key.Enter
                            , disabledStyling = submitDisabled
                            }
                            UI.viewButton.large
                        , paragraph
                            [ Font.center
                            ]
                            [ text "Need some help choosing an algorithm? If you would like to explore your options check out "
                            , UI.viewWebResourceLink
                                [ testid "alg-db-link" ]
                                shared.palette
                                (WebResource.AlgDBPLL pllCase)
                                "this AlgDb entry"
                            , text ", if you on the other hand want to just follow the advice and guidance of an experienced cuber check out "
                            , UI.viewWebResourceLink
                                [ testid "expert-link" ]
                                shared.palette
                                (WebResource.ExpertGuidancePLL pllCase)
                                "this link to J Perm's PLL + Fingertricks video"
                            ]
                        ]
            )
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
            viewDoesntMatchCaseError palette


sharedErrorAttributes : UI.Palette -> List (Attribute msg)
sharedErrorAttributes palette =
    [ errorMessageTestType
    , Font.color palette.error
    , UI.fontSize.medium
    , UI.spacingAll.verySmall
    , Font.center
    , width fill
    ]


viewDoesntMatchCaseError : UI.Palette -> Element msg
viewDoesntMatchCaseError palette =
    paragraph (testid "algorithm-doesnt-match-case" :: sharedErrorAttributes palette)
        [ text "The algorithm doesn't solve the case. Try double checking it from the source" ]


viewParsingError : UI.Palette -> Algorithm.FromStringError -> Element msg
viewParsingError palette error =
    case error of
        Algorithm.EmptyAlgorithm ->
            paragraph (testid "input-required" :: sharedErrorAttributes palette)
                [ text "input required" ]

        Algorithm.InvalidTurnable { inputString, invalidTurnable, errorIndex } ->
            column
                (testid "invalid-turnable" :: sharedErrorAttributes palette)
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
                (testid "invalid-turn-length" :: sharedErrorAttributes palette)
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
                (testid "repeated-turnable" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "You repeated a turnable twice in a row. Try combining the two into one, such as U2 U becoming U':" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.WideMoveStylesMixed { inputString, errorIndex, invalidWideMove } ->
            column
                (testid "wide-move-styles-mixed" :: sharedErrorAttributes palette)
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
                (testid "turn-would-work-without-interruption" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "An invalid turn was found. The turn would become valid if the underlined interruption was removed:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    interruptionStart
                    interruptionEnd
                ]

        Algorithm.ApostropheWrongSideOfLength { inputString, errorIndex } ->
            column
                (testid "apostrophe-wrong-side-of-length" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "Turn is invalid. It would be valid if you swapped the apostrophe to the other side of the length though:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.UnclosedParenthesis { inputString, openParenthesisIndex } ->
            column
                (testid "unclosed-parenthesis" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "There is an unclosed parenthesis, add a closing parenthesis to fix this:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    openParenthesisIndex
                    (openParenthesisIndex + 1)
                ]

        Algorithm.UnmatchedClosingParenthesis { inputString, errorIndex } ->
            column
                (testid "unmatched-closing-parenthesis" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "There is an unmatched closing parenthesis, remove it or add an opening parenthesis to fix this:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.EmptyParentheses { inputString, errorIndex } ->
            column
                (testid "empty-parentheses" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "There were no turns inside this set of parentheses, remove the parentheses or add some turns inside to fix it:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.NestedParentheses { inputString, errorIndex } ->
            column
                (testid "nested-parentheses" :: sharedErrorAttributes palette)
                [ paragraph []
                    [ text "There are nested parentheses in this algorithm which is not allowed. Remove them to fix it:" ]
                , viewUnderlinedPlaceWhereErrorOcurred
                    inputString
                    errorIndex
                    (errorIndex + 1)
                ]

        Algorithm.InvalidSymbol { inputString, errorIndex, symbol } ->
            column
                (testid "invalid-symbol" :: sharedErrorAttributes palette)
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
            paragraph (sharedErrorAttributes palette)
                [ text "Congratulations! You somehow managed to make your algorithm span several lines of text which is not allowed and the input shouldn't even let you do. If you want to proceed you should undo it though :)" ]

        Algorithm.UnexpectedError _ ->
            -- The error having been sent to our developers already occurs in the update function
            paragraph (sharedErrorAttributes palette)
                [ text "Congratulations! You somehow managed to make our algorithm parser error in a way we had never expected to happen. If you're online a simple error description (with no personal data) has already been sent to the developers so hopefully this will soon be fixed, but thanks for helping find our edge cases! Until then see if you can figure out the problem with your algorithm yourself, or maybe try out writing it from scratch again" ]


viewUnderlinedPlaceWhereErrorOcurred : String -> Int -> Int -> Element msg
viewUnderlinedPlaceWhereErrorOcurred inputString start end =
    let
        -- We purposefully split them into lists of text so that
        -- the wrapped row can do its thing, which it can't with
        -- a piece of pre-formatted text. And trying things like
        -- htmlAttribute white-space: pre-wrap doesn't play well
        -- with the Elm UI internals
        beforeUnderline =
            String.left start inputString
                |> String.toList
                |> List.map String.fromChar
                |> List.map text

        underlinedCharacters =
            String.slice start end inputString
                |> String.toList
                |> List.map String.fromChar
                |> List.map
                    (\char ->
                        el [ below (text "~") ] <|
                            text char
                    )

        afterUnderline =
            String.dropLeft end inputString
                |> String.toList
                |> List.map String.fromChar
                |> List.map text
    in
    wrappedRow
        [ centerX
        , UI.spacingVertical.small
        ]
    <|
        beforeUnderline
            ++ underlinedCharacters
            ++ afterUnderline
