module ViewCube exposing (viewLazy)

import Css exposing (htmlCubeTestType)
import Cube
import Cube.Advanced
import Element
import Element.Lazy
import Html
import Shared


viewLazy :
    Shared.CubeViewOptions
    -> List (Html.Attribute msg)
    ->
        { pixelSize : Int
        , displayAngle : Cube.DisplayAngle
        , annotateFaces : Bool
        }
    -> Cube.Cube
    -> Element.Element msg
viewLazy options attributes parameters cube =
    Element.el (List.map Element.htmlAttribute <| htmlCubeTestType :: attributes) <|
        Element.Lazy.lazy5
            viewHelper
            options
            parameters.annotateFaces
            parameters.displayAngle
            parameters.pixelSize
            cube


viewHelper :
    Shared.CubeViewOptions
    -> Bool
    -> Cube.DisplayAngle
    -> Int
    -> Cube.Cube
    -> Element.Element msg
viewHelper options annotateFaces displayAngle pixelSize notFinalCube =
    let
        notFinalParameters =
            { annotateFaces = annotateFaces
            , displayAngle = displayAngle
            , pixelSize = pixelSize
            }

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
    Element.html <| viewFn [] finalParameters finalCube
