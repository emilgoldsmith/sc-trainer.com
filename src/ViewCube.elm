module ViewCube exposing (uBLWithLetters, uFRNoLetters, uFRWithLetters)

import Css exposing (htmlTestid)
import Cube
import Element
import Html


uBLWithLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uBLWithLetters attributes size cube =
    Element.html <| Cube.viewUBLWithLetters (htmlTestid "cube" :: attributes) size cube


uFRNoLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uFRNoLetters attributes size cube =
    Element.html <| Cube.viewUFRNoLetters (htmlTestid "cube" :: attributes) size cube


uFRWithLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uFRWithLetters attributes size cube =
    Element.html <| Cube.viewUFRWithLetters (htmlTestid "cube" :: attributes) size cube
