module PLLTrainer.States.StartPage exposing (Transitions, state)

import Css exposing (htmlTestid, testid)
import Cube
import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import Key
import List.Nonempty
import PLL
import PLLTrainer.ButtonWithShortcut
import PLLTrainer.State
import Shared
import UI
import User
import View
import ViewCube
import ViewportSize
import WebResource


state : Shared.Model -> Transitions msg -> PLLTrainer.State.State msg () ()
state shared transitions =
    PLLTrainer.State.static
        { view =
            view
                shared
                transitions
        , nonRepeatedKeyUpHandler =
            Just <|
                \key ->
                    if key == Key.Space then
                        transitions.startTest

                    else
                        transitions.noOp
        }



-- TRANSITIONS


type alias Transitions msg =
    { startTest : msg
    , noOp : msg
    }



-- VIEW


view :
    Shared.Model
    -> Transitions msg
    -> PLLTrainer.State.View msg
view shared transitions =
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            el
                [ testid "start-page-container"
                , centerY
                , scrollbarY
                , width fill
                , UI.fontSize.large
                ]
            <|
                column
                    [ UI.spacingAll.small
                    , centerX
                    , width (fill |> maximum (ViewportSize.width shared.viewportSize * 3 // 4))
                    , UI.paddingVertical.veryLarge
                    ]
                <|
                    [ if User.hasAttemptedAPLLTestCase shared.user then
                        recurringUserStatistics shared

                      else
                        newUserWelcome shared
                    , UI.viewDivider shared.palette
                    , paragraph
                        [ UI.fontSize.veryLarge
                        , centerX
                        , Font.center
                        , testid "cube-start-explanation"
                        , Region.heading 1
                        ]
                      <|
                        [ text "Orient Solved Cube Like This:" ]
                    , el [ centerX ] <|
                        ViewCube.view shared.cubeViewOptions
                            [ htmlTestid "cube-start-state" ]
                            { pixelSize = 200
                            , displayAngle = Cube.ufrDisplayAngle
                            , annotateFaces = True
                            }
                            Cube.solved
                    , PLLTrainer.ButtonWithShortcut.view
                        shared.hardwareAvailable
                        [ testid "start-button"
                        , centerX
                        ]
                        { onPress = Just transitions.startTest
                        , labelText = "Start"
                        , color = shared.palette.primary
                        , keyboardShortcut = Key.Space
                        }
                        UI.viewButton.large
                    , UI.viewDivider shared.palette
                    , column
                        [ testid "instructions-text"
                        , Font.center
                        , centerX
                        , UI.spacingAll.small
                        ]
                        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ] [ text "Instructions:" ]
                        , paragraph []
                            [ text "When you press the start button (or space) you will have a second to get your cube in "
                            , UI.viewWebResourceLink
                                []
                                shared.palette
                                WebResource.HomeGripExplanation
                                "home grip"
                            , text ". Then a "
                            , UI.viewWebResourceLink
                                []
                                shared.palette
                                WebResource.PLLExplanation
                                "PLL"
                            , text " case will show up and the timer will start. If you successfully recognize the case apply the moves to your cube that would solve the cube on screen (including pre- and post-"
                            , UI.viewWebResourceLink
                                []
                                shared.palette
                                WebResource.AUFExplanation
                                "AUF"
                            , text
                                "), and then press anything to stop the timer. If you don't recognize the case just press anything when you are sure you can't recall it. Things to press include any keyboard key, the screen and your mouse/touchpad."
                            ]
                        , paragraph []
                            [ text "You will then be displayed how the cube should look if you applied the correct moves. Click the button labelled correct or wrong depending on whether your cube matches the one on screen, and if you got it correct, simply continue to the next case without any change to your cube!"
                            ]
                        , paragraph []
                            [ text "If you got it wrong the application will help you decide if you need to solve the cube to reset it before being able to continue to the next case, avoiding it where possible."
                            ]
                        ]
                    , UI.viewDivider shared.palette
                    , column
                        [ testid "learning-resources"
                        , centerX
                        , UI.spacingAll.small
                        ]
                        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1, Font.center ] [ text "Learning Resources:" ]
                        , UI.viewUnorderedList [ centerX ]
                            [ paragraph []
                                [ UI.viewWebResourceLink
                                    []
                                    shared.palette
                                    WebResource.TwoSidedPllRecognitionGuide
                                    "Two Sided PLL Recognition Guide"
                                ]
                            , paragraph []
                                [ UI.viewWebResourceLink
                                    []
                                    shared.palette
                                    WebResource.PLLAlgorithmsResource
                                    "Fast PLL Algorithms And Finger Tricks"
                                ]
                            , paragraph []
                                [ text "And just generally make sure you drill you algorithms until you can do them without looking!" ]
                            ]
                        ]
                    ]
    }


recurringUserStatistics : Shared.Model -> Element msg
recurringUserStatistics shared =
    let
        allStatistics =
            User.pllStatistics shared.user

        ( averageTimeMs, averageTPS ) =
            allStatistics
                |> List.filterMap
                    (\statistics ->
                        case statistics of
                            User.CaseLearnedStatistics { lastThreeAverageMs, lastThreeAverageTPS } ->
                                Just ( lastThreeAverageMs, lastThreeAverageTPS )

                            User.CaseNotLearnedStatistics _ ->
                                Nothing
                    )
                |> List.unzip
                |> (\( times, tpses ) ->
                        let
                            length =
                                toFloat (List.length times)
                        in
                        ( List.sum times / length, List.sum tpses / length )
                   )
    in
    column
        [ width (fill |> maximum 600), Font.center, UI.spacingVertical.extremelySmall, centerX ]
        [ paragraph [ Region.heading 1, UI.fontSize.veryLarge ] [ text "Statistics:" ]
        , UI.viewDivider shared.palette
        , wrappedRow [ width fill, UI.spacingHorizontal.extremelySmall ]
            [ paragraph [ testid "num-cases-tried" ]
                [ text "Cases Tried: "
                , text <| String.fromInt <| List.length allStatistics
                ]
            , paragraph [ testid "num-cases-not-yet-tried" ]
                [ text "Cases Not Yet Tried: "
                , text <| String.fromInt <| List.Nonempty.length PLL.all - List.length allStatistics
                ]
            ]
        , UI.viewDivider shared.palette
        , paragraph [] [ text "Cases most in need of practice by last three attempts:" ]
        , UI.viewOrderedList [ testid "worst-three-cases", centerX, UI.spacingVertical.extremelySmall ] <|
            (allStatistics
                |> User.orderByWorstCaseFirst
                |> List.take 3
                |> List.map
                    (\statistics ->
                        (case statistics of
                            User.CaseLearnedStatistics { lastThreeAverageMs, lastThreeAverageTPS, pll } ->
                                PLL.getLetters pll
                                    ++ "-perm: "
                                    ++ UI.formatTPS lastThreeAverageTPS
                                    ++ " ("
                                    ++ UI.formatMilliseconds lastThreeAverageMs
                                    ++ ")"

                            User.CaseNotLearnedStatistics pll ->
                                PLL.getLetters pll
                                    ++ "-perm: DNF"
                        )
                            |> text
                            |> el [ testid "worst-case-list-item" ]
                    )
            )
        , UI.viewDivider shared.palette
        , paragraph [] [ text "Overall:" ]
        , wrappedRow [ width fill, UI.spacingHorizontal.extremelySmall ]
            [ paragraph [ testid "average-tps" ] [ text "Average TPS: ", text <| UI.formatFloatTwoDecimals averageTPS ]
            , paragraph [ testid "average-time" ] [ text "Average Time: ", text <| UI.formatMilliseconds averageTimeMs ]
            ]
        , UI.viewDivider shared.palette
        , paragraph [ testid "statistics-shortcomings-explanation" ] [ el [ Font.bold ] <| text "Disclaimer: ", text "These statistics still leave a lot to be wanted. They are not yet comprehensive, and are for example also biased towards longer algorithms scoring better in TPS as recognition time is included. We aspire for much better statistics in the future but this will do for a start as it is non-trivial to improve." ]
        ]


newUserWelcome : Shared.Model -> Element msg
newUserWelcome shared =
    column
        [ testid "welcome-text"
        , Font.center
        , centerX
        , UI.spacingAll.small
        ]
        [ paragraph [ UI.fontSize.veryLarge, Region.heading 1 ]
            [ text "Welcome!" ]
        , paragraph []
            [ text "This is a "
            , UI.viewWebResourceLink [] shared.palette WebResource.PLLExplanation "PLL"
            , text " trainer which attempts to remove both the manual scrambling to create more flow, and to make practice closer to real life by timing from "
            , UI.viewWebResourceLink [] shared.palette WebResource.HomeGripExplanation "home grip"
            , text
                ", and including recognition and pre- and post-"
            , UI.viewWebResourceLink [] shared.palette WebResource.AUFExplanation "AUF"
            , text
                " in timing. Many improvements including intelligently displaying your weakest cases to enhance learning are planned!"
            ]
        ]
