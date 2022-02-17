module ViewCube exposing (view)

import Css exposing (htmlCubeTestType)
import Cube
import Cube.Advanced
import Element
import Html
import Shared


{-| Remember that in order to utilize the lazy ability of this
function you need to be using the exact same cube by reference
which in most cases means saving it in the model
-}
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
view options attributes notFinalParameters notFinalCube =
    let
        viewFn =
            if Shared.shouldUseDebugViewForVisualTesting options then
                Cube.Advanced.debugViewAllowingVisualTesting

            else
                Cube.view

        finalCube =
            Cube.applyAlgorithm (Shared.getExtraAlgToApplyToAllCubes options) notFinalCube

        finalParameters =
            Shared.getSizeOverride options
                |> Maybe.map (\newSize -> { notFinalParameters | pixelSize = newSize })
                |> Maybe.withDefault notFinalParameters
    in
    Element.html <| viewFn (htmlCubeTestType :: attributes) finalParameters finalCube
