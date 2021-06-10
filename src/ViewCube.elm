module ViewCube exposing (uBLWithLetters, uFRNoLetters, uFRWithLetters)

import Css exposing (htmlCubeTestType)
import Cube
import Element
import Html


uBLWithLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uBLWithLetters attributes size cube =
    Element.html <| Cube.viewUBLWithLetters (htmlCubeTestType :: attributes) size cube


uFRNoLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uFRNoLetters attributes size cube =
    Element.html <| Cube.viewUFRNoLetters (htmlCubeTestType :: attributes) size cube


uFRWithLetters : List (Html.Attribute msg) -> Int -> Cube.Cube -> Element.Element msg
uFRWithLetters attributes size cube =
    Element.html <| Cube.viewUFRWithLetters (htmlCubeTestType :: attributes) size cube
