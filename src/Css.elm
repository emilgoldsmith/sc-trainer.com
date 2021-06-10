module Css exposing (errorMessageTestType, htmlCubeTestType, htmlTestid, testid)

import Element exposing (..)
import Html
import Html.Attributes


testid : String -> Attribute msg
testid =
    htmlTestid >> htmlAttribute


htmlTestid : String -> Html.Attribute msg
htmlTestid =
    Html.Attributes.attribute "data-testid"


htmlCubeTestType : Html.Attribute msg
htmlCubeTestType =
    htmlTestType "cube"


errorMessageTestType : Attribute msg
errorMessageTestType =
    htmlAttribute <|
        htmlTestType "error-message"


htmlTestType : String -> Html.Attribute msg
htmlTestType =
    Html.Attributes.attribute "data-test-type"
