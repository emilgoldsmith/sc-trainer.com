module UI exposing (Button, Palette, defaultPalette, fontSize, viewButton, viewDivider, viewWebResourceLink)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Utils.Css exposing (testid)
import WebResource



-- Views


viewWebResourceLink : Palette -> WebResource.WebResource -> String -> Element msg
viewWebResourceLink palette resource labelText =
    newTabLink
        [ Font.underline
        , mouseOver
            [ Font.color palette.mouseOverLink
            ]
        , focused
            [ Border.shadow
                { offset = ( 0, 0 )
                , blur = 0
                , size = 3
                , color = palette.focusBorder
                }
            ]
        ]
        { label = text labelText
        , url = WebResource.getUrl resource
        }


viewDivider : Palette -> Element msg
viewDivider palette =
    el
        [ testid "divider"
        , Border.solid
        , width fill
        , Border.widthEach { top = 2, left = 0, right = 0, bottom = 0 }
        , Border.color palette.black
        ]
        none


type alias Button msg =
    List (Attribute msg) -> { onPress : Maybe msg, color : Color, label : Int -> Element msg } -> Element msg


baseButton : Int -> Button msg
baseButton size attributes { onPress, label, color } =
    let
        paddingSize =
            size * 2 // 3

        roundingSize =
            size // 3
    in
    Input.button (attributes ++ [ Background.color color, padding paddingSize, Border.rounded roundingSize ]) { onPress = onPress, label = label size }


viewButton : { large : Button msg1, customSize : Int -> Button msg2 }
viewButton =
    { large = baseButton <| fontScale 2, customSize = baseButton }



-- Palette


type alias Palette =
    { -- General
      primary : Color
    , correct : Color
    , wrong : Color
    , black : Color

    -- Link
    , mouseOverLink : Color

    -- Focus
    , focusBorder : Color
    }


defaultPalette : Palette
defaultPalette =
    { -- General
      primary = rgb255 0 128 0
    , correct = rgb255 0 128 0
    , wrong = rgb255 255 0 0
    , black = rgb255 0 0 0

    -- Link
    , mouseOverLink = rgb255 125 125 125

    -- Focus
    , focusBorder = rgb255 155 203 255
    }



-- Sizings


fontScale : Int -> Int
fontScale =
    modular 16 (4 / 3) >> round


fontSize : { small : Attr decorative msg, medium : Attr a b, large : Attr c d, veryLarge : Attr e f }
fontSize =
    { small = Font.size <| fontScale -1
    , medium = Font.size <| fontScale 1
    , large = Font.size <| fontScale 2
    , veryLarge = Font.size <| fontScale 3
    }
