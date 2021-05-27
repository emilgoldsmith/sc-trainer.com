module ViewportSize exposing (ViewportSize, build, classifyDevice, height, minDimension, width)

import Element


type ViewportSize
    = ViewportSize
        { width : Int
        , height : Int
        }


build : { width : Int, height : Int } -> ViewportSize
build =
    ViewportSize


width : ViewportSize -> Int
width (ViewportSize internals) =
    internals.width


height : ViewportSize -> Int
height (ViewportSize internals) =
    internals.height


minDimension : ViewportSize -> Int
minDimension (ViewportSize internals) =
    min internals.width internals.height


classifyDevice : ViewportSize -> Element.Device
classifyDevice (ViewportSize widthAndHeight) =
    Element.classifyDevice widthAndHeight
