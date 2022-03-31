module ViewCube exposing (view)

import Algorithm
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
                debugViewWithDefaultTheme

            else
                Cube.view

        extraAlgToApplyToAllCubes =
            Shared.getExtraAlgToApplyToAllCubes options

        -- We use this if else statement to ensure it doesn't break the lazy call when
        -- we aren't adding an extra alg to all cubes
        finalCube =
            if extraAlgToApplyToAllCubes /= Algorithm.empty then
                Cube.applyAlgorithm extraAlgToApplyToAllCubes notFinalCube

            else
                notFinalCube

        finalParameters =
            Shared.getSizeOverride options
                |> Maybe.map (\newSize -> { notFinalParameters | pixelSize = newSize })
                |> Maybe.withDefault notFinalParameters
    in
    Element.html <| viewFn (htmlCubeTestType :: attributes) finalParameters finalCube


debugViewWithDefaultTheme :
    List (Html.Attribute msg)
    ->
        { pixelSize : Int
        , displayAngle : Cube.DisplayAngle
        , annotateFaces : Bool
        }
    -> Cube.Cube
    -> Html.Html msg
debugViewWithDefaultTheme attributes args =
    Cube.Advanced.debugViewAllowingVisualTesting attributes
        { theme = Cube.Advanced.defaultTheme
        , pixelSize = args.pixelSize
        , displayAngle = args.displayAngle
        , annotateFaces = args.annotateFaces
        }
