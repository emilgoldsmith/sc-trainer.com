module Utils.Css exposing (testid)

import Html exposing (..)
import Html.Attributes exposing (..)


testid : String -> Attribute msg
testid =
    attribute "data-testid"
