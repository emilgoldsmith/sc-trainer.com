module Utils.Css exposing (htmlTestid, testid)

import Element exposing (..)
import Html
import Html.Attributes


testid : String -> Attribute msg
testid =
    htmlTestid >> htmlAttribute


htmlTestid : String -> Html.Attribute msg
htmlTestid =
    Html.Attributes.attribute "data-testid"
