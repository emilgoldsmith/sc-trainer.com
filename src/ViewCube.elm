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
        , theme : Cube.Advanced.CubeTheme
        }
    -> Cube.Cube
    -> Element.Element msg
view options attributes notFinalParameters cube =
    let
        viewFn =
            if Shared.shouldUseDebugViewForVisualTesting options then
                Cube.Advanced.debugViewAllowingVisualTesting

            else
                Cube.Advanced.view

        withDisplayAngleOverride =
            Shared.getDisplayAngleOverride options
                |> Maybe.map (\newDisplayAngle -> { notFinalParameters | displayAngle = newDisplayAngle })
                |> Maybe.withDefault notFinalParameters

        finalParameters =
            Shared.getSizeOverride options
                |> Maybe.map (\newSize -> { withDisplayAngleOverride | pixelSize = newSize })
                |> Maybe.withDefault withDisplayAngleOverride
    in
    Element.html <| viewFn (htmlCubeTestType :: attributes) finalParameters cube
