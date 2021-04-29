module ViewCube exposing (uBLWithLetters, uFRNoLetters, uFRWithLetters)

import Cube
import Element
import Html.Lazy
import Utils.Css exposing (testid)


uBLWithLetters : Int -> Cube.Cube -> Element.Element msg
uBLWithLetters size cube =
    Element.el [ testid "cube" ] <| Element.html <| Html.Lazy.lazy2 Cube.viewUBLWithLetters size cube


uFRNoLetters : Int -> Cube.Cube -> Element.Element msg
uFRNoLetters size cube =
    Element.el [ testid "cube" ] <| Element.html <| Html.Lazy.lazy2 Cube.viewUFRNoLetters size cube


uFRWithLetters : Int -> Cube.Cube -> Element.Element msg
uFRWithLetters size cube =
    Element.el [ testid "cube" ] <| Element.html <| Html.Lazy.lazy2 Cube.viewUFRWithLetters size cube
