module UI exposing (Palette, defaultPalette, viewDivider, viewWebResourceLink)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
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



-- Palette


type alias Palette =
    { black : Color
    , mouseOverLink : Color
    , focusBorder : Color
    }


defaultPalette : Palette
defaultPalette =
    { -- General
      black = rgb255 0 0 0

    -- Link
    , mouseOverLink = rgb255 125 125 125

    -- Focus
    , focusBorder = rgb255 155 203 255
    }
