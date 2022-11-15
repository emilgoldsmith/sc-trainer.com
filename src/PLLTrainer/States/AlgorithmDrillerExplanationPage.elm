module PLLTrainer.States.AlgorithmDrillerExplanationPage exposing (Model, Msg, Transitions, state)

import Algorithm
import Browser.Events
import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import ErrorMessage
import Html.Attributes
import Json.Decode
import Key
import PLL
import PLLRecognition
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import PLLTrainer.Subscription
import PLLTrainer.TestCase
import Ports
import Shared
import UI
import User
import View
import ViewCube


state : Shared.Model -> Transitions msg -> Arguments -> (Msg -> msg) -> PLLTrainer.State.State msg Msg Model
state shared transitions arguments toMsg =
    PLLTrainer.State.element
        { init = init
        , update = update
        , subscriptions = subscriptions transitions
        , view = view shared transitions arguments toMsg
        }



-- TRANSITIONS


type alias Transitions msg =
    { startDrills : msg
    , noOp : msg
    }


type alias Arguments =
    { testCase : PLLTrainer.TestCase.TestCase
    , wasCorrect : Bool
    }



-- INIT


type alias Model =
    { errorMessageClosed : Bool
    }


init : ( Model, Cmd msg )
init =
    ( { errorMessageClosed = False }, Cmd.none )



-- UPDATE


type Msg
    = CloseErrorWithoutSending
    | SendError String


update : Msg -> Model -> ( Model, Cmd msg )
update msg _ =
    case msg of
        CloseErrorWithoutSending ->
            ( { errorMessageClosed = True }, Cmd.none )

        SendError error ->
            ( { errorMessageClosed = True }
            , Ports.logError error
            )



-- SUBSCRIPTIONS


subscriptions : Transitions msg -> Model -> PLLTrainer.Subscription.Subscription msg
subscriptions transitions _ =
    PLLTrainer.Subscription.onlyBrowserEvents <|
        Browser.Events.onKeyUp <|
            Json.Decode.map
                (\key ->
                    case key of
                        Key.Space ->
                            transitions.startDrills

                        _ ->
                            transitions.noOp
                )
                Key.decodeNonRepeatedKeyEvent



-- VIEW


view : Shared.Model -> Transitions msg -> Arguments -> (Msg -> msg) -> Model -> PLLTrainer.State.View msg
view shared transitions { testCase, wasCorrect } toMsg model =
    let
        errorPopup description =
            ErrorMessage.popupOverlay shared.viewportSize
                shared.palette
                { errorDescription = description
                , closeWithoutSending = toMsg CloseErrorWithoutSending
                , sendError = toMsg (SendError description)
                }

        maybePLLAlgorithm =
            User.getPLLAlgorithm (PLLTrainer.TestCase.pll testCase) shared.user

        ( maybeRecognitionSpec, maybeErrorPopupOverlay ) =
            case maybePLLAlgorithm of
                Nothing ->
                    ( Nothing
                    , Just <| errorPopup "No PLL algorithm was stored for this case"
                    )

                Just pllAlgorithm ->
                    case
                        PLL.getUniqueTwoSidedRecognitionSpecification
                            { pllAlgorithmUsed = pllAlgorithm
                            , recognitionAngle = PLL.ufrRecognitionAngle
                            , preAUF = PLLTrainer.TestCase.preAUF testCase
                            , pll = PLLTrainer.TestCase.pll testCase
                            }
                    of
                        Err (PLL.IncorrectPLLAlgorithm _ _) ->
                            ( Nothing
                            , Just <| errorPopup "Stored PLL algorithm doesn't solve the case"
                            )

                        Ok recognitionSpec ->
                            ( Just recognitionSpec, Nothing )
    in
    { overlays =
        View.buildOverlays
            (List.filterMap identity
                [ if model.errorMessageClosed then
                    Nothing

                  else
                    maybeErrorPopupOverlay
                ]
            )
    , body =
        View.fullScreenBody
            (\{ scrollableContainerId } ->
                el
                    [ testid "algorithm-driller-explanation-page-container"
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
                        , UI.paddingAll.veryLarge
                        , UI.spacingVertical.medium
                        ]
                        [ textColumn
                            [ testid "algorithm-driller-explanation"
                            , width fill
                            , centerX
                            , UI.fontSize.medium
                            , UI.spacingVertical.small
                            ]
                            [ paragraph [ UI.fontSize.veryLarge, Font.center, centerX ]
                                [ if wasCorrect then
                                    text "A Bit More Practice Needed"

                                  else
                                    text "Time To Drill Your Algorithm"
                                ]
                            , paragraph []
                                [ if wasCorrect then
                                    el [ testid "correct-text" ] <| text "Good job solving the case correctly! Since you did it slower than your target parameters it seems a bit more practice is needed though, maybe to derust the algorithm or to learn it a bit better. "

                                  else
                                    el [ testid "wrong-text" ] <| text "It looks like this case was new to you. "
                                , text "This is therefore a prompt to just take some time to practice the case and algorithm that you just attempted and is shown below here again. Your aim should be to reach a level of comfort where you can recognize the case confidently, and execute the algorithm fluidly without looking at the cube. We don't recommend continuing on with other cases until you have reached that level of confidence with this case."
                                ]
                            , paragraph []
                                [ text "You are of course welcome to close the app and return when you are ready, but if you have kept the app open and finished practicing feel free to press the continue button. This will lead you to a little test that will time you on this case until you get it correct three times in a row. In addition it only counts a case as correct if executed fast enough for the target parameters you have set for a case being learned. When you have passed three times in a row you will go back into the normal flow of practicing cases."
                                ]
                            ]
                        , el [ centerX ] <|
                            ViewCube.view shared.cubeViewOptions
                                [ htmlTestid "case-to-drill" ]
                                { pixelSize = 200
                                , displayAngle = Cube.ufrDisplayAngle
                                , annotateFaces = False
                                , theme = User.cubeTheme shared.user
                                }
                            <|
                                PLLTrainer.TestCase.toCube shared.user testCase
                        , paragraph
                            [ testid "algorithm-to-drill"
                            , centerX
                            , Font.bold
                            , Font.center
                            , UI.fontSize.large
                            ]
                            [ text
                                (testCase
                                    |> PLLTrainer.TestCase.toAlg
                                        { addFinalReorientationToAlgorithm = False }
                                        shared.user
                                    |> Algorithm.toString
                                )
                            ]
                        , case maybeRecognitionSpec of
                            Nothing ->
                                none

                            Just recognitionSpec ->
                                column
                                    [ testid "recognition-explanation"
                                    , centerX
                                    , UI.spacingVertical.extremelySmall
                                    , UI.fontSize.medium
                                    ]
                                    [ paragraph
                                        []
                                        [ el [ Font.bold ] <| text "PLL Recognition: "
                                        , text (PLLRecognition.specToPLLRecognitionString recognitionSpec)
                                        ]
                                    , paragraph []
                                        [ el [ Font.bold ] <| text "Post-AUF Recognition: "
                                        , text (PLLRecognition.specToPostAUFString recognitionSpec)
                                        ]
                                    ]
                        , PLLTrainer.ButtonWithShortcut.view
                            shared.hardwareAvailable
                            [ testid "continue-button"
                            , centerX
                            ]
                            { onPress = Just transitions.startDrills
                            , labelText = "Continue"
                            , keyboardShortcut = Key.Space
                            , color = shared.palette.primary
                            }
                            UI.viewButton.large
                        ]
            )
    }
