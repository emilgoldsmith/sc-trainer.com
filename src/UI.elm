module UI exposing (Button, Palette, defaultPalette, fontSize, paddingAll, paddingVertical, spacing, viewButton, viewDivider, viewUnorderedList, viewWebResourceLink)

-- We can't expose all of Element as it clashes with the spacing export

import Element as El
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Utils.Css exposing (testid)
import WebResource



-- Views


viewWebResourceLink : Palette -> WebResource.WebResource -> String -> El.Element msg
viewWebResourceLink palette resource labelText =
    El.newTabLink
        [ Font.underline
        , El.mouseOver
            [ Font.color palette.mouseOverLink
            ]
        , El.focused
            [ Border.shadow
                { offset = ( 0, 0 )
                , blur = 0
                , size = 3
                , color = palette.focusBorder
                }
            ]
        ]
        { label = El.text labelText
        , url = WebResource.getUrl resource
        }


viewDivider : Palette -> El.Element msg
viewDivider palette =
    El.el
        [ testid "divider"
        , Border.solid
        , El.width El.fill
        , Border.widthEach { top = 2, left = 0, right = 0, bottom = 0 }
        , Border.color palette.black
        ]
        El.none


type alias Button msg =
    List (El.Attribute msg) -> { onPress : Maybe msg, color : El.Color, label : Int -> El.Element msg } -> El.Element msg


baseButton : Int -> Button msg
baseButton size attributes { onPress, label, color } =
    let
        paddingSize =
            size * 2 // 3

        roundingSize =
            (paddingSize + size) // 5
    in
    Input.button (attributes ++ [ Background.color color, El.padding paddingSize, Border.rounded roundingSize ]) { onPress = onPress, label = label size }


viewButton : { large : Button msg1, customSize : Int -> Button msg2 }
viewButton =
    { large = baseButton <| fontScale 2, customSize = baseButton }


viewUnorderedList : List (El.Attribute msg) -> List (El.Element msg) -> El.Element msg
viewUnorderedList attributes listItemContents =
    let
        listItems =
            List.map (\content -> El.row [ spacing.verySmall ] [ El.text "-", content ]) listItemContents
    in
    El.column (spacing.small :: attributes) listItems



-- Palette


type alias Palette =
    { -- General
      primary : El.Color
    , correct : El.Color
    , wrong : El.Color
    , black : El.Color

    -- Link
    , mouseOverLink : El.Color

    -- Focus
    , focusBorder : El.Color
    }


defaultPalette : Palette
defaultPalette =
    { -- General
      primary = El.rgb255 0 128 0
    , correct = El.rgb255 0 128 0
    , wrong = El.rgb255 255 0 0
    , black = El.rgb255 0 0 0

    -- Link
    , mouseOverLink = El.rgb255 125 125 125

    -- Focus
    , focusBorder = El.rgb255 155 203 255
    }



-- Sizings


type alias Sizes decorative msg =
    { verySmall : El.Attr decorative msg
    , small : El.Attr decorative msg
    , medium : El.Attr decorative msg
    , large : El.Attr decorative msg
    , veryLarge : El.Attr decorative msg
    }


type alias Scale =
    Int -> Int


buildSizes : (Int -> El.Attr decorative msg) -> Scale -> Sizes decorative msg
buildSizes buildAttribute scale =
    { verySmall = buildAttribute <| scale -2
    , small = buildAttribute <| scale -1
    , medium = buildAttribute <| scale 1
    , large = buildAttribute <| scale 2
    , veryLarge = buildAttribute <| scale 3
    }


fontScale : Int -> Int
fontScale =
    El.modular 16 (4 / 3) >> round


fontSize : Sizes decorative msg
fontSize =
    buildSizes Font.size fontScale


spaceScale : Int -> Int
spaceScale =
    El.modular 21 (4 / 3) >> round


spacing : Sizes () msg
spacing =
    buildSizes El.spacing spaceScale


paddingScale : Int -> Int
paddingScale =
    El.modular 4 2 >> round


paddingAll : Sizes () msg
paddingAll =
    buildSizes El.padding paddingScale


paddingVertical : Sizes () msg
paddingVertical =
    buildSizes (El.paddingXY 0) paddingScale
