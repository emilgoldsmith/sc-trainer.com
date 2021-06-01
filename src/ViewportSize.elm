module ViewportSize exposing (DeviceClass(..), Orientation(..), ViewportSize, build, getDeviceClass, getDeviceOrientation, height, minDimension, width)

import Element


type ViewportSize
    = ViewportSize
        { width : Int
        , height : Int
        }


type DeviceClass
    = Phone
    | Tablet
    | Desktop
    | BigDesktop


type Orientation
    = Portrait
    | Landscape


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


getDeviceClass : ViewportSize -> DeviceClass
getDeviceClass (ViewportSize widthAndHeight) =
    case Element.classifyDevice widthAndHeight |> .class of
        Element.Phone ->
            Phone

        Element.Tablet ->
            Tablet

        Element.Desktop ->
            Desktop

        Element.BigDesktop ->
            BigDesktop


getDeviceOrientation : ViewportSize -> Orientation
getDeviceOrientation (ViewportSize widthAndHeight) =
    case Element.classifyDevice widthAndHeight |> .orientation of
        Element.Portrait ->
            Portrait

        Element.Landscape ->
            Landscape
