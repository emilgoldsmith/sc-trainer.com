module ViewCube exposing (view)

import Css exposing (htmlCubeTestType)
import Cube
import Element
import Html


view :
    List (Html.Attribute msg)
    ->
        { pixelSize : Int
        , displayAngle : Cube.DisplayAngle
        , annotateFaces : Bool
        }
    -> Cube.Cube
    -> Element.Element msg
view attributes parameters =
    Element.html << Cube.view (htmlCubeTestType :: attributes) parameters
