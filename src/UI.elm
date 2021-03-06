module UI exposing (Button, Palette, defaultPalette, fontSize, formatFloatTwoDecimals, formatMilliseconds, formatTPS, paddingAll, paddingHorizontal, paddingVertical, spacingAll, spacingHorizontal, spacingVertical, viewButton, viewDivider, viewOrderedList, viewUnorderedList, viewWebResourceLink)

-- We can't expose all of Element as it clashes with the spacing export

import Css exposing (testid)
import Element as El
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
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


viewWebResourceLink : List (El.Attribute msg) -> Palette -> WebResource.WebResource -> String -> El.Element msg
viewWebResourceLink attributes palette resource labelText =
    El.newTabLink
        ([ Font.underline
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
            ++ attributes
        )
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
    Input.button ([ Background.color color, El.padding paddingSize, Border.rounded roundingSize ] ++ attributes) { onPress = onPress, label = label size }


viewButton : { large : Button msg1, customSize : Int -> Button msg2 }
viewButton =
    { large = baseButton <| fontScale 2, customSize = baseButton }


viewUnorderedList : List (El.Attribute msg) -> List (El.Element msg) -> El.Element msg
viewUnorderedList attributes listItemContents =
    let
        listItems =
            List.map (\content -> El.row [ spacingAll.verySmall ] [ El.text "-", content ]) listItemContents
    in
    El.column (spacingAll.small :: attributes) listItems


viewOrderedList : List (El.Attribute msg) -> List (El.Element msg) -> El.Element msg
viewOrderedList attributes listItemContents =
    let
        listItems =
            List.indexedMap
                (\index content ->
                    El.row
                        [ spacingHorizontal.verySmall ]
                        [ El.text (String.fromInt (index + 1) ++ "."), El.paragraph [] [ content ] ]
                )
                listItemContents
    in
    El.column attributes listItems



-- Palette


type alias Palette =
    { -- General
      primary : El.Color
    , correct : El.Color
    , wrong : El.Color
    , black : El.Color
    , label : El.Color
    , errorText : El.Color

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
    , label = El.rgb255 125 125 125
    , errorText = El.rgb255 255 0 0

    -- Link
    , mouseOverLink = El.rgb255 125 125 125

    -- Focus
    , focusBorder = El.rgb255 155 203 255
    }



-- Sizings


type alias Sizes decorative msg =
    { extremelySmall : El.Attr decorative msg
    , verySmall : El.Attr decorative msg
    , small : El.Attr decorative msg
    , medium : El.Attr decorative msg
    , large : El.Attr decorative msg
    , veryLarge : El.Attr decorative msg
    , extremelyLarge : El.Attr decorative msg
    }


type alias Scale =
    Int -> Int


buildSizes : (Int -> El.Attr decorative msg) -> Scale -> Sizes decorative msg
buildSizes buildAttribute scale =
    { extremelySmall = buildAttribute <| scale -3
    , verySmall = buildAttribute <| scale -2
    , small = buildAttribute <| scale -1
    , medium = buildAttribute <| scale 1
    , large = buildAttribute <| scale 2
    , veryLarge = buildAttribute <| scale 3
    , extremelyLarge = buildAttribute <| scale 4
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


spacingAll : Sizes () msg
spacingAll =
    buildSizes El.spacing spaceScale


spacingVertical : Sizes () msg
spacingVertical =
    buildSizes (El.spacingXY 0) spaceScale


spacingHorizontal : Sizes () msg
spacingHorizontal =
    buildSizes (\space -> El.spacingXY space 0) spaceScale


paddingScale : Int -> Int
paddingScale =
    El.modular 4 2 >> round


paddingAll : Sizes () msg
paddingAll =
    buildSizes El.padding paddingScale


paddingVertical : Sizes () msg
paddingVertical =
    buildSizes (El.paddingXY 0) paddingScale


paddingHorizontal : Sizes () msg
paddingHorizontal =
    buildSizes (\xPadding -> El.paddingXY xPadding 0) paddingScale
