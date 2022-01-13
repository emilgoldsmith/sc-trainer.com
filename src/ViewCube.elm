module ViewCube exposing (view)

import Css exposing (htmlCubeTestType)
import Cube
import Cube.Advanced
import Element
import Html
import Shared


view :
    Shared.CubeViewOptions
    -> List (Html.Attribute msg)
    ->
        { pixelSize : Int
        , displayAngle : Cube.DisplayAngle
        , annotateFaces : Bool
        }
    -> Cube.Cube
    -> Element.Element msg
view options attributes parameters notFinalCube =
    let
        viewFn =
            if Shared.shouldUseDebugViewForVisualTesting options then
                Cube.Advanced.debugViewAllowingVisualTesting

            else
                Cube.view

        finalCube =
            Cube.applyAlgorithm (Shared.getExtraAlgToApplyToAllCubes options) notFinalCube
    in
    Element.html <| viewFn (htmlCubeTestType :: attributes) parameters finalCube
