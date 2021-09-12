module Key exposing (Key(..), decodeKeyEventTargetNodeName, decodeNonRepeatedKeyEvent, onEnter)

import Element
import Html.Events
import Json.Decode


type Key
    = Space
    | W
    | One
    | Two
    | Three
    | Enter
    | OtherKey String


decodeNonRepeatedKeyEvent : Json.Decode.Decoder Key
decodeNonRepeatedKeyEvent =
    let
        fields =
            Json.Decode.map2 Tuple.pair decodeKey decodeKeyRepeat
    in
    fields
        |> Json.Decode.andThen
            (\( key, isRepeated ) ->
                if isRepeated == True then
                    Json.Decode.fail "Was a repeated key press"

                else
                    Json.Decode.succeed key
            )


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Json.Decode.Decoder Key
decodeKey =
    Json.Decode.map toKey (Json.Decode.field "key" Json.Decode.string)


decodeKeyRepeat : Json.Decode.Decoder Bool
decodeKeyRepeat =
    Json.Decode.field "repeat" Json.Decode.bool


decodeKeyEventTargetNodeName : Json.Decode.Decoder String
decodeKeyEventTargetNodeName =
    Json.Decode.at [ "target", "nodeName" ] Json.Decode.string


toKey : String -> Key
toKey keyString =
    case keyString of
        " " ->
            Space

        "w" ->
            W

        "W" ->
            W

        "1" ->
            One

        "2" ->
            Two

        "3" ->
            Three

        "Enter" ->
            Enter

        _ ->
            OtherKey keyString


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (decodeNonRepeatedKeyEvent
                |> Json.Decode.andThen
                    (\key ->
                        if key == Enter then
                            Json.Decode.succeed msg

                        else
                            Json.Decode.fail "Not the enter key"
                    )
            )
        )
