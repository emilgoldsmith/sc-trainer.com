module PLLTrainer.ButtonWithShortcut exposing (view, viewSmall)

import Element exposing (..)
import Element.Font as Font
import Key exposing (Key)
import Shared
import UI


view : Shared.HardwareAvailable -> List (Attribute msg) -> { onPress : Maybe msg, labelText : String, color : Color, keyboardShortcut : Key } -> UI.Button msg -> Element msg
view hardwareAvailable attributes { onPress, labelText, keyboardShortcut, color } button =
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

                Key.OtherKey keyStr ->
                    keyStr

        shortcutText =
            text <| "(" ++ keyString ++ ")"

        withShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        column [ centerX ]
                            [ el [ centerX, Font.size fontSize ] <| text labelText
                            , el [ centerX, Font.size (fontSize // 2) ] shortcutText
                            ]
                }

        withoutShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        el [ centerX, Font.size fontSize ] <| text labelText
                }
    in
    if hardwareAvailable.keyboard then
        withShortcutLabel

    else
        withoutShortcutLabel


viewSmall : Shared.HardwareAvailable -> List (Attribute msg) -> { onPress : Maybe msg, labelText : String, color : Color, keyboardShortcut : Key } -> UI.Button msg -> Element msg
viewSmall hardwareAvailable attributes { onPress, labelText, keyboardShortcut, color } button =
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

                Key.OtherKey keyStr ->
                    keyStr

        shortcutText =
            text <| "(" ++ keyString ++ ")"

        withShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        column [ centerX, spacing 3 ]
                            [ el [ centerX, Font.size fontSize ] <| text labelText
                            , el [ centerX, Font.size (fontSize * 3 // 4) ] shortcutText
                            ]
                }

        withoutShortcutLabel =
            button attributes
                { onPress = onPress
                , color = color
                , label =
                    \fontSize ->
                        el [ centerX, Font.size fontSize ] <| text labelText
                }
    in
    if hardwareAvailable.keyboard then
        withShortcutLabel

    else
        withoutShortcutLabel
