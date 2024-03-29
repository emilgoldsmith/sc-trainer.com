module UI exposing (Button, Palette, Sizes, defaultPalette, fontSize, formatFloatTwoDecimals, formatMilliseconds, formatTPS, materialIconColor, paddingAll, paddingHorizontal, paddingVertical, spacingAll, spacingHorizontal, spacingVertical, viewButton, viewDarkDivider, viewLightDivider, viewOrderedList, viewUnorderedList, viewWebResourceLink)

-- We can't expose all of Element as it clashes with the spacing export

import Color
import Css exposing (disabledStylingActiveAttribute, testid)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Material.Icons.Types
import Round
import WebResource



-- Number Formatting


formatTPS : Float -> String
formatTPS tps =
    formatFloatTwoDecimals tps ++ "TPS"


formatMilliseconds : Float -> String
formatMilliseconds ms =
    formatFloatTwoDecimals (ms / 1000) ++ "s"


formatFloatTwoDecimals : Float -> String
formatFloatTwoDecimals =
    Round.round 2



-- Views


viewWebResourceLink : List (Attribute msg) -> Palette -> WebResource.WebResource -> String -> Element msg
viewWebResourceLink attributes palette resource labelText =
    newTabLink
        (Font.underline
            :: mouseOver [ Font.color palette.mouseOverLink ]
            :: focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , blur = 0
                    , size = 3
                    , color = palette.focusBorder
                    }
                ]
            :: attributes
        )
        { label = text labelText
        , url = WebResource.getUrl resource
        }


viewDarkDivider : Palette -> Element msg
viewDarkDivider palette =
    el
        [ testid "divider"
        , Border.solid
        , width fill
        , Border.widthEach { top = 2, left = 0, right = 0, bottom = 0 }
        , Border.color palette.darkText
        ]
        none


viewLightDivider : Palette -> Element msg
viewLightDivider palette =
    el
        [ testid "divider"
        , Border.solid
        , width fill
        , Border.widthEach { top = 2, left = 0, right = 0, bottom = 0 }
        , Border.color palette.lightText
        ]
        none


type alias Button msg =
    List (Attribute msg) -> Palette -> { onPress : Maybe msg, color : Color, label : Int -> Element msg, disabledStyling : Bool } -> Element msg


baseButton : Int -> Button msg
baseButton size attributes palette { onPress, label, color, disabledStyling } =
    let
        paddingSize =
            size * 2 // 3

        roundingSize =
            (paddingSize + size) // 5
    in
    Input.button
        (padding paddingSize
            :: Border.rounded roundingSize
            :: attributes
            ++ (if disabledStyling then
                    [ Background.color palette.disabledGrey
                    , disabledStylingActiveAttribute
                    ]

                else
                    [ Background.color color ]
               )
        )
        { onPress = onPress, label = label size }


viewButton : { large : Button msg1, customSize : Int -> Button msg2 }
viewButton =
    { large = baseButton <| fontScale 2, customSize = baseButton }


viewUnorderedList : List (Attribute msg) -> List (Element msg) -> Element msg
viewUnorderedList attributes listItemContents =
    let
        listItems =
            List.map (\content -> row [ spacingAll.verySmall ] [ text "-", content ]) listItemContents
    in
    column (spacingAll.small :: attributes) listItems


viewOrderedList : List (Attribute msg) -> List (Element msg) -> Element msg
viewOrderedList attributes listItemContents =
    let
        listItems =
            List.indexedMap
                (\index content ->
                    row
                        [ spacingHorizontal.verySmall ]
                        [ text (String.fromInt (index + 1) ++ "."), paragraph [] [ content ] ]
                )
                listItemContents
    in
    column attributes listItems



-- Palette


type alias Palette =
    { -- General
      background : Color
    , primaryButton : Color
    , secondaryButton : Color
    , disabledGrey : Color
    , correct : Color
    , wrong : Color
    , darkText : Color
    , lightText : Color
    , error : Color
    , label : Color
    , greyBackground : Color
    , transparent : Color

    -- Link
    , mouseOverLink : Color

    -- Focus
    , focusBorder : Color
    }


defaultPalette : Palette
defaultPalette =
    { -- General
      background = rgb255 255 255 255
    , primaryButton = rgb255 0 128 0
    , secondaryButton = rgb255 0 0 128
    , disabledGrey = rgb255 102 102 102
    , correct = rgb255 0 128 0
    , wrong = rgb255 255 0 0
    , darkText = rgb255 0 0 0
    , lightText = rgb255 255 255 255
    , error = rgb255 255 0 0
    , label = rgb255 125 125 125
    , greyBackground = rgb255 180 180 180
    , transparent = rgba 0 0 0 0

    -- Link
    , mouseOverLink = rgb255 125 125 125

    -- Focus
    , focusBorder = rgb255 155 203 255
    }


materialIconColor : Color -> Material.Icons.Types.Coloring
materialIconColor color =
    color
        |> toRgb
        |> Color.fromRgba
        |> Material.Icons.Types.Color



-- Sizings


type alias Sizes decorative msg =
    { verySmallest : Attr decorative msg
    , extremelySmall : Attr decorative msg
    , verySmall : Attr decorative msg
    , small : Attr decorative msg
    , medium : Attr decorative msg
    , large : Attr decorative msg
    , veryLarge : Attr decorative msg
    , extremelyLarge : Attr decorative msg
    }


type alias Scale =
    Int -> Int


buildSizes : (Int -> Attr decorative msg) -> Scale -> Sizes decorative msg
buildSizes buildAttribute scale =
    { verySmallest = buildAttribute <| scale -4
    , extremelySmall = buildAttribute <| scale -3
    , verySmall = buildAttribute <| scale -2
    , small = buildAttribute <| scale -1
    , medium = buildAttribute <| scale 1
    , large = buildAttribute <| scale 2
    , veryLarge = buildAttribute <| scale 3
    , extremelyLarge = buildAttribute <| scale 4
    }


fontScale : Int -> Int
fontScale =
    modular 16 (4 / 3) >> round


fontSize : Sizes decorative msg
fontSize =
    buildSizes Font.size fontScale


spaceScale : Int -> Int
spaceScale =
    modular 21 (4 / 3) >> round


spacingAll : Sizes () msg
spacingAll =
    buildSizes spacing spaceScale


spacingVertical : Sizes () msg
spacingVertical =
    buildSizes (spacingXY 0) spaceScale


spacingHorizontal : Sizes () msg
spacingHorizontal =
    buildSizes (\space -> spacingXY space 0) spaceScale


paddingScale : Int -> Int
paddingScale =
    modular 4 2 >> round


paddingAll : Sizes () msg
paddingAll =
    buildSizes padding paddingScale


paddingVertical : Sizes () msg
paddingVertical =
    buildSizes (paddingXY 0) paddingScale


paddingHorizontal : Sizes () msg
paddingHorizontal =
    buildSizes (\xPadding -> paddingXY xPadding 0) paddingScale
