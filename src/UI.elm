module UI exposing (viewWebResourceLink)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
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
