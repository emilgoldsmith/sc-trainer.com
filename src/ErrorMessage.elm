module ErrorMessage exposing (popupOverlay, viewInline)

import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Material.Icons as FilledIcons
import UI
import ViewportSize exposing (ViewportSize)


popupOverlay :
    ViewportSize
    -> UI.Palette
    -> { errorDescription : String, sendError : msg, closeWithoutSending : msg }
    -> Attribute msg
popupOverlay viewportSize palette { errorDescription, sendError, closeWithoutSending } =
    let
        maxWidth =
            min 500 (ViewportSize.width viewportSize * 9 // 10)
    in
    inFront <|
        column
            [ testid "error-popup-container"
            , errorMessageTestType
            , alignBottom
            , centerX
            , moveUp 10
            , width (shrink |> maximum maxWidth)
            , Border.shadow
                { offset = ( 0, 5 )
                , size = 0
                , blur = 15
                , color = rgba255 0 0 0 0.35
                }
            ]
            [ column
                [ Background.color palette.error
                , UI.spacingVertical.verySmallest
                , width fill
                , UI.paddingAll.large
                ]
                [ row
                    [ UI.fontSize.veryLarge
                    , Font.bold
                    , Font.color palette.lightText
                    , width fill
                    ]
                    [ el [] <|
                        html <|
                            FilledIcons.error 35 (UI.materialIconColor palette.lightText)
                    , el [ moveDown 3 ] <| text "Error"
                    , Input.button
                        [ alignRight, testid "close-button" ]
                        { onPress = Just closeWithoutSending
                        , label =
                            html <|
                                FilledIcons.close 25 (UI.materialIconColor palette.lightText)
                        }
                    ]
                , UI.viewLightDivider palette
                , paragraph
                    [ Font.center
                    , UI.fontSize.medium
                    , Font.color palette.lightText
                    ]
                    [ text errorDescription ]
                ]
            , column
                [ Background.color palette.background
                , width fill
                , UI.paddingAll.large
                , UI.fontSize.medium
                , UI.spacingVertical.verySmallest
                ]
                [ paragraph []
                    [ text "Send error to developers to notify them it needs fixing?"
                    ]
                , row [ width fill ]
                    [ el [ width fill ] <|
                        UI.viewButton.large [ centerX, testid "dont-send-error-button" ]
                            palette
                            { onPress = Just closeWithoutSending
                            , color = rgb255 125 125 125
                            , label = \size -> el [ Font.size size ] <| text "No"
                            , disabledStyling = False
                            }
                    , el [ width fill ] <|
                        UI.viewButton.large [ centerX, testid "send-error-button" ]
                            palette
                            { onPress = Just sendError
                            , color = palette.error
                            , label = \size -> el [ Font.size size ] <| text "Yes"
                            , disabledStyling = False
                            }
                    ]
                ]
            ]


viewInline :
    UI.Palette
    -> { errorDescription : String, sendError : msg }
    -> Element msg
viewInline palette { errorDescription, sendError } =
    column
        [ testid "inline-error-container"
        , errorMessageTestType
        , width fill
        , Border.shadow
            { offset = ( 0, 0 )
            , size = 0
            , blur = 5
            , color = rgba255 0 0 0 0.35
            }
        ]
        [ column
            [ Background.color palette.error
            , UI.spacingVertical.verySmallest
            , width fill
            , UI.paddingAll.large
            ]
            [ row
                [ UI.fontSize.veryLarge
                , Font.bold
                , Font.color palette.lightText
                , width fill
                ]
                [ el [] <|
                    html <|
                        FilledIcons.error 35 (UI.materialIconColor palette.lightText)
                , el [ moveDown 3 ] <| text "Error"
                ]
            , UI.viewLightDivider palette
            , paragraph
                [ Font.center
                , UI.fontSize.medium
                , Font.color palette.lightText
                ]
                [ text errorDescription ]
            ]
        , column
            [ Background.color palette.background
            , width fill
            , UI.paddingAll.large
            , UI.fontSize.medium
            , UI.spacingVertical.verySmallest
            ]
            [ paragraph []
                [ text "Send error to developers to notify them it needs fixing?"
                ]
            , row [ width fill ]
                [ el [ width fill ] <|
                    UI.viewButton.large [ centerX, testid "send-error-button" ]
                        palette
                        { onPress = Just sendError
                        , color = palette.error
                        , label = \size -> el [ Font.size size ] <| text "Send Error"
                        , disabledStyling = False
                        }
                ]
            ]
        ]
