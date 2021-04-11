module Components.Cube exposing (viewUBL, viewUFR)

import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Algorithm as Algorithm
import Models.Cube as Cube
import Utils.Css exposing (htmlTestid)



-- Exports


viewUFR : Int -> Cube.Cube -> Element.Element msg
viewUFR =
    getCubeHtml ( YDegrees -20, XDegrees -15, ZDegrees 5 )


viewUBL : Int -> Cube.Cube -> Element.Element msg
viewUBL cubeSize cube =
    let
        rotatedCube =
            cube
                |> Cube.applyAlgorithm (Algorithm.build [ Algorithm.Turn Algorithm.Y Algorithm.Halfway Algorithm.Clockwise ])
    in
    viewUFR cubeSize rotatedCube



-- PARAMETERS


type alias CubeTheme =
    { up : Color
    , down : Color
    , right : Color
    , left : Color
    , front : Color
    , back : Color
    , plastic : Color
    }


type alias Color =
    String


defaultTheme : CubeTheme
defaultTheme =
    { up = "white"
    , down = "yellow"
    , right = "red"
    , left = "orange"
    , front = "green"
    , back = "blue"
    , plastic = "black"
    }


cubeContainerSize : Float
cubeContainerSize =
    1


wholeCubeSideLength : Float
wholeCubeSideLength =
    cubeContainerSize / 1.4


cubieSideLength : Float
cubieSideLength =
    wholeCubeSideLength / 3


cubieBorderWidth : Float
cubieBorderWidth =
    cubieSideLength / 10



-- HTML


getCubeHtml : CubeRotation -> Int -> Cube.Cube -> Element.Element msg
getCubeHtml rotation cubeSize cube =
    Element.html <|
        let
            rendering =
                Cube.render cube
        in
        div
            [ htmlTestid "cube"
            , style "font-size" <| String.fromInt cubeSize ++ "px"
            , style "width" (String.fromFloat cubeContainerSize ++ "em")
            , style "height" (String.fromFloat cubeContainerSize ++ "em")
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            ]
            [ div
                [ style "width" (String.fromFloat wholeCubeSideLength ++ "em")
                , style "height" (String.fromFloat wholeCubeSideLength ++ "em")
                , style "position" "relative"
                , style "transform-origin" ("center center -" ++ String.fromFloat (wholeCubeSideLength / 2) ++ "em")
                , style "transform-style" "preserve-3d"
                , toTransformCSS rotation
                ]
              <|
                List.map (\( a, b ) -> displayCubie defaultTheme b a)
                    (getRenderedCorners rendering ++ getRenderedEdges rendering ++ getRenderedCenters rendering)
            ]


displayCubie : CubeTheme -> Coordinates -> Cube.CubieRendering -> Html msg
displayCubie theme { fromFront, fromLeft, fromTop } rendering =
    div
        [ style "position" "absolute"
        , style "width" (String.fromFloat cubieSideLength ++ "em")
        , style "height" (String.fromFloat cubieSideLength ++ "em")
        , style "transform-origin" ("center center -" ++ String.fromFloat (cubieSideLength / 2) ++ "em")
        , style "transform-style" "preserve-3d"
        , style "display" "inline-block"

        -- Position the cubie correctly
        , style "top" (String.fromFloat (fromTop * cubieSideLength) ++ "em")
        , style "left" (String.fromFloat (fromLeft * cubieSideLength) ++ "em")
        , style "transform" ("translateZ(" ++ String.fromFloat (fromFront * cubieSideLength * -1) ++ "em)")
        ]
        (List.map (\face -> displayCubieFace theme face rendering) Cube.faces)


displayCubieFace : CubeTheme -> Cube.Face -> Cube.CubieRendering -> Html msg
displayCubieFace theme face rendering =
    div
        [ style "transform" <| (face |> getFaceRotation |> toCssRotationString)
        , style "background-color" <| getColorString theme (getFaceColor face rendering)
        , style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
        , style "width" (String.fromFloat cubieSideLength ++ "em")
        , style "height" (String.fromFloat cubieSideLength ++ "em")

        -- Notice the negative sign here
        , style "transform-origin" ("center center -" ++ String.fromFloat (cubieSideLength / 2) ++ "em")
        , style "transform-style" "preserve-3d"
        , style "border" (theme.plastic ++ " solid " ++ String.fromFloat cubieBorderWidth ++ "em")
        , style "box-sizing" "border-box"
        ]
        []



-- LOGIC AND MAPPINGS


getFaceRotation : Cube.Face -> AxisRotation
getFaceRotation face =
    case face of
        Cube.UpOrDown Cube.U ->
            XDegrees 90

        Cube.UpOrDown Cube.D ->
            XDegrees -90

        Cube.FrontOrBack Cube.F ->
            XDegrees 0

        Cube.FrontOrBack Cube.B ->
            YDegrees 180

        Cube.LeftOrRight Cube.L ->
            YDegrees -90

        Cube.LeftOrRight Cube.R ->
            YDegrees 90


getFaceColor : Cube.Face -> Cube.CubieRendering -> Cube.Color
getFaceColor face rendering =
    case face of
        Cube.UpOrDown Cube.U ->
            rendering.u

        Cube.UpOrDown Cube.D ->
            rendering.d

        Cube.FrontOrBack Cube.F ->
            rendering.f

        Cube.FrontOrBack Cube.B ->
            rendering.b

        Cube.LeftOrRight Cube.L ->
            rendering.l

        Cube.LeftOrRight Cube.R ->
            rendering.r


getColorString : CubeTheme -> Cube.Color -> String
getColorString theme color =
    case color of
        Cube.UpColor ->
            theme.up

        Cube.DownColor ->
            theme.down

        Cube.RightColor ->
            theme.right

        Cube.LeftColor ->
            theme.left

        Cube.FrontColor ->
            theme.front

        Cube.BackColor ->
            theme.back

        Cube.PlasticColor ->
            theme.plastic


type alias Coordinates =
    { fromFront : Float
    , fromLeft : Float
    , fromTop : Float
    }


type AxisRotation
    = XDegrees Int
    | YDegrees Int
    | ZDegrees Int


toTransformCSS : CubeRotation -> Attribute msg
toTransformCSS rotation =
    style "transform"
        (rotation
            |> tupleToList
            |> List.map toCssRotationString
            |> String.join " "
        )


toCssRotationString : AxisRotation -> String
toCssRotationString axisRotation =
    case axisRotation of
        XDegrees deg ->
            "rotateX(" ++ String.fromInt deg ++ "deg)"

        YDegrees deg ->
            "rotateY(" ++ String.fromInt deg ++ "deg)"

        ZDegrees deg ->
            "rotateZ(" ++ String.fromInt deg ++ "deg)"


tupleToList : ( a, a, a ) -> List a
tupleToList ( a, b, c ) =
    [ a, b, c ]


{-| 3D rotation, note that order of axes makes a difference
-}
type alias CubeRotation =
    ( AxisRotation, AxisRotation, AxisRotation )


getRenderedCorners : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates )
getRenderedCorners rendering =
    List.map (getRenderedCorner rendering) Cube.cornerLocations


getRenderedCorner : Cube.Rendering -> Cube.CornerLocation -> ( Cube.CubieRendering, Coordinates )
getRenderedCorner rendering location =
    let
        cornerRendering =
            case location of
                ( Cube.U, Cube.F, Cube.L ) ->
                    rendering.ufl

                ( Cube.U, Cube.F, Cube.R ) ->
                    rendering.ufr

                ( Cube.U, Cube.B, Cube.R ) ->
                    rendering.ubr

                ( Cube.U, Cube.B, Cube.L ) ->
                    rendering.ubl

                ( Cube.D, Cube.B, Cube.L ) ->
                    rendering.dbl

                ( Cube.D, Cube.B, Cube.R ) ->
                    rendering.dbr

                ( Cube.D, Cube.F, Cube.R ) ->
                    rendering.dfr

                ( Cube.D, Cube.F, Cube.L ) ->
                    rendering.dfl
    in
    ( cornerRendering, getCornerCoordinates location )


getCornerCoordinates : Cube.CornerLocation -> Coordinates
getCornerCoordinates ( uOrD, fOrB, lOrR ) =
    { fromFront =
        if fOrB == Cube.F then
            0

        else
            2
    , fromLeft =
        if lOrR == Cube.L then
            0

        else
            2
    , fromTop =
        if uOrD == Cube.U then
            0

        else
            2
    }


getRenderedEdges : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates )
getRenderedEdges rendering =
    List.map (getRenderedEdge rendering) Cube.edgeLocations


getRenderedEdge : Cube.Rendering -> Cube.EdgeLocation -> ( Cube.CubieRendering, Coordinates )
getRenderedEdge rendering location =
    let
        edgeRendering =
            case location of
                Cube.M ( Cube.U, Cube.F ) ->
                    rendering.uf

                Cube.M ( Cube.U, Cube.B ) ->
                    rendering.ub

                Cube.M ( Cube.D, Cube.F ) ->
                    rendering.df

                Cube.M ( Cube.D, Cube.B ) ->
                    rendering.db

                Cube.S ( Cube.U, Cube.L ) ->
                    rendering.ul

                Cube.S ( Cube.U, Cube.R ) ->
                    rendering.ur

                Cube.S ( Cube.D, Cube.L ) ->
                    rendering.dl

                Cube.S ( Cube.D, Cube.R ) ->
                    rendering.dr

                Cube.E ( Cube.F, Cube.L ) ->
                    rendering.fl

                Cube.E ( Cube.F, Cube.R ) ->
                    rendering.fr

                Cube.E ( Cube.B, Cube.L ) ->
                    rendering.bl

                Cube.E ( Cube.B, Cube.R ) ->
                    rendering.br
    in
    ( edgeRendering, getEdgeCoordinates location )


getEdgeCoordinates : Cube.EdgeLocation -> Coordinates
getEdgeCoordinates location =
    case location of
        Cube.M ( uOrD, fOrB ) ->
            { fromFront =
                if fOrB == Cube.F then
                    0

                else
                    2
            , fromLeft = 1
            , fromTop =
                if uOrD == Cube.U then
                    0

                else
                    2
            }

        Cube.S ( uOrD, lOrR ) ->
            { fromFront = 1
            , fromLeft =
                if lOrR == Cube.L then
                    0

                else
                    2
            , fromTop =
                if uOrD == Cube.U then
                    0

                else
                    2
            }

        Cube.E ( fOrB, lOrR ) ->
            { fromFront =
                if fOrB == Cube.F then
                    0

                else
                    2
            , fromLeft =
                if lOrR == Cube.L then
                    0

                else
                    2
            , fromTop = 1
            }


getRenderedCenters : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates )
getRenderedCenters rendering =
    List.map (getRenderedCenter rendering) Cube.centerLocations


getRenderedCenter : Cube.Rendering -> Cube.CenterLocation -> ( Cube.CubieRendering, Coordinates )
getRenderedCenter rendering location =
    let
        centerRendering =
            case location of
                Cube.CenterLocation (Cube.UpOrDown Cube.U) ->
                    rendering.u

                Cube.CenterLocation (Cube.UpOrDown Cube.D) ->
                    rendering.d

                Cube.CenterLocation (Cube.LeftOrRight Cube.L) ->
                    rendering.l

                Cube.CenterLocation (Cube.LeftOrRight Cube.R) ->
                    rendering.r

                Cube.CenterLocation (Cube.FrontOrBack Cube.F) ->
                    rendering.f

                Cube.CenterLocation (Cube.FrontOrBack Cube.B) ->
                    rendering.b
    in
    ( centerRendering, getCenterCoordinates location )


getCenterCoordinates : Cube.CenterLocation -> Coordinates
getCenterCoordinates location =
    case location of
        Cube.CenterLocation (Cube.UpOrDown Cube.U) ->
            { fromFront = 1
            , fromLeft = 1
            , fromTop = 0
            }

        Cube.CenterLocation (Cube.UpOrDown Cube.D) ->
            { fromFront = 1
            , fromLeft = 1
            , fromTop = 2
            }

        Cube.CenterLocation (Cube.LeftOrRight Cube.L) ->
            { fromFront = 1
            , fromLeft = 0
            , fromTop = 1
            }

        Cube.CenterLocation (Cube.LeftOrRight Cube.R) ->
            { fromFront = 1
            , fromLeft = 2
            , fromTop = 1
            }

        Cube.CenterLocation (Cube.FrontOrBack Cube.F) ->
            { fromFront = 0
            , fromLeft = 1
            , fromTop = 1
            }

        Cube.CenterLocation (Cube.FrontOrBack Cube.B) ->
            { fromFront = 2
            , fromLeft = 1
            , fromTop = 1
            }
