module UI exposing (viewDivider, viewWebResourceLink)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Utils.Css exposing (testid)
import WebResource



-- Views


viewWebResourceLink : WebResource.WebResource -> String -> Element msg
viewWebResourceLink resource labelText =
    newTabLink
        [ Font.underline
        , mouseOver
            [ Font.color (rgb255 125 125 125)
            ]
        , focused
            [ Border.shadow
                { offset = ( 0, 0 )
                , blur = 0
                , size = 3
                , color = rgb255 155 203 255
                }
            ]
        ]
        { label = text labelText
        , url = WebResource.getUrl resource
        }


viewDivider : Element msg
viewDivider =
    el
        [ testid "divider"
        , Border.solid
        , width fill
        , Border.widthEach { top = 2, left = 0, right = 0, bottom = 0 }
        , Border.color defaultPalette.black
        ]
        none



-- Palette


type alias Palette =
    { black : Color
    }


defaultPalette : Palette
defaultPalette =
    { black = rgb255 0 0 0
    }
