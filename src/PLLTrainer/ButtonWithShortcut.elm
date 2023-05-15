module PLLTrainer.ButtonWithShortcut exposing (view, viewSmall)

import Element exposing (..)
import Element.Font as Font
import Key exposing (Key)
import Shared
import UI


view : Shared.HardwareAvailable -> List (Attribute msg) -> UI.Palette -> { onPress : Maybe msg, labelText : String, color : Color, disabledStyling : Bool, keyboardShortcut : Key } -> UI.Button msg -> Element msg
view hardwareAvailable attributes palette { onPress, labelText, disabledStyling, keyboardShortcut, color } button =
    let
        keyString =
            case keyboardShortcut of
                Key.W ->
                    "W"

                Key.Space ->
                    "Space"

                Key.One ->
                    "1"

                Key.Two ->
                    "2"

                Key.Three ->
                    "3"

                Key.Enter ->
                    "Enter"

                Key.OtherKey keyStr ->
                    keyStr

        shortcutText =
            text <| "(" ++ keyString ++ ")"

        withShortcutLabel =
            button attributes
                palette
                { onPress = onPress
                , color = color
                , disabledStyling = disabledStyling
                , label =
                    \fontSize ->
                        column [ centerX ]
                            [ el [ centerX, Font.size fontSize ] <| text labelText
                            , el [ centerX, Font.size (fontSize // 2) ] shortcutText
                            ]
                }

        withoutShortcutLabel =
            button attributes
                palette
                { onPress = onPress
                , color = color
                , disabledStyling = disabledStyling
                , label =
                    \fontSize ->
                        el [ centerX, Font.size fontSize ] <| text labelText
                }
    in
    if hardwareAvailable.keyboard then
        withShortcutLabel

    else
        withoutShortcutLabel


viewSmall : Shared.HardwareAvailable -> List (Attribute msg) -> UI.Palette -> { onPress : Maybe msg, labelText : String, color : Color, disabledStyling : Bool, keyboardShortcut : Key } -> UI.Button msg -> Element msg
viewSmall hardwareAvailable attributes palette { onPress, labelText, disabledStyling, keyboardShortcut, color } button =
    let
        keyString =
            case keyboardShortcut of
                Key.W ->
                    "W"

                Key.Space ->
                    "Space"

                Key.One ->
                    "1"

                Key.Two ->
                    "2"

                Key.Three ->
                    "3"

                Key.Enter ->
                    "Enter"

                Key.OtherKey keyStr ->
                    keyStr

        shortcutText =
            text <| "(" ++ keyString ++ ")"

        withShortcutLabel =
            button attributes
                palette
                { onPress = onPress
                , color = color
                , disabledStyling = disabledStyling
                , label =
                    \fontSize ->
                        column [ centerX, spacing 3 ]
                            [ el [ centerX, Font.size fontSize ] <| text labelText
                            , el [ centerX, Font.size (fontSize * 3 // 4) ] shortcutText
                            ]
                }

        withoutShortcutLabel =
            button attributes
                palette
                { onPress = onPress
                , color = color
                , disabledStyling = disabledStyling
                , label =
                    \fontSize ->
                        el [ centerX, Font.size fontSize ] <| text labelText
                }
    in
    if hardwareAvailable.keyboard then
        withShortcutLabel

    else
        withoutShortcutLabel
