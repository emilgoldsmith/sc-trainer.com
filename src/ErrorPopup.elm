module ErrorPopup exposing (overlay)

import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Material.Icons as FilledIcons
import UI
import ViewportSize exposing (ViewportSize)


overlay :
    ViewportSize
    -> UI.Palette
    -> { errorDescription : String, sendError : msg, closeWithoutSending : msg }
    -> Attribute msg
overlay viewportSize palette { errorDescription, sendError, closeWithoutSending } =
    let
        maxWidth =
            min 500 (ViewportSize.width viewportSize * 9 // 10)
    in
    inFront <|
        column
            [ testid "error-popup"
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
                [ Background.color palette.errorText
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
                    [ html <|
                        FilledIcons.error 35 (UI.materialIconColor palette.lightText)
                    , el [ moveDown 3 ] <| text "Error"
                    , Input.button
                        [ alignRight ]
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
                        UI.viewButton.large [ centerX ]
                            { onPress = Just closeWithoutSending
                            , color = rgb255 125 125 125
                            , label = \size -> el [ Font.size size ] <| text "No"
                            }
                    , el [ width fill ] <|
                        UI.viewButton.large [ centerX ]
                            { onPress = Just sendError
                            , color = palette.errorText
                            , label = \size -> el [ Font.size size ] <| text "Yes"
                            }
                    ]
                ]
            ]
