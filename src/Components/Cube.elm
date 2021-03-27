module Components.Cube exposing (injectStyles, view)

import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Cube as Cube
import Random
import Utils.Css exposing (htmlTestid)



-- Exports


view : Float -> Cube.Cube -> Element.Element msg
view cubeSize cube =
    Element.html <|
        let
            rendering =
                Cube.render cube
        in
        div [ class classes.container, htmlTestid "cube", style "font-size" <| String.fromFloat cubeSize ++ "px" ]
            [ div [ class classes.wholeCube ] <|
                List.map (\( a, b ) -> displayCubie b a)
                    (getRenderedCorners rendering ++ getRenderedEdges rendering ++ getRenderedCenters rendering)
            ]


injectStyles : Html msg
injectStyles =
    let
        original =
            css defaultTheme

        compressedCss =
            original
                |> String.split "\n"
                |> List.map String.trim
                |> String.join ""
    in
    styleTag [] [ text compressedCss ]



-- HTML


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


type alias Coordinates =
    { fromFront : Float
    , fromLeft : Float
    , fromTop : Float
    }


displayCubie : Coordinates -> Cube.CubieRendering -> Html msg
displayCubie { fromFront, fromLeft, fromTop } rendering =
    div
        [ class classes.cubie
        , style "top" (String.fromFloat (fromTop * cubieSideLength) ++ "em")
        , style "left" (String.fromFloat (fromLeft * cubieSideLength) ++ "em")
        , style "transform" ("translateZ(" ++ String.fromFloat (fromFront * cubieSideLength * -1) ++ "em)")
        ]
        (List.map (\face -> displayCubieFace face rendering) Cube.faces)


displayCubieFace : Cube.Face -> Cube.CubieRendering -> Html msg
displayCubieFace face rendering =
    div [ classList (getFaceClasses face ++ [ ( getColorClass face rendering, True ) ]) ] []


getFaceClasses : Cube.Face -> List ( String, Bool )
getFaceClasses cubeFace =
    let
        faceSpecifierClass =
            case cubeFace of
                Cube.UpOrDown Cube.U ->
                    classes.upFace

                Cube.UpOrDown Cube.D ->
                    classes.downFace

                Cube.LeftOrRight Cube.R ->
                    classes.rightFace

                Cube.LeftOrRight Cube.L ->
                    classes.leftFace

                Cube.FrontOrBack Cube.F ->
                    classes.frontFace

                Cube.FrontOrBack Cube.B ->
                    classes.backFace
    in
    [ ( classes.face, True ), ( faceSpecifierClass, True ) ]



-- Theme


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



-- CSS


styleTag : List (Attribute msg) -> List (Html msg) -> Html msg
styleTag =
    node "style"


css : CubeTheme -> String
css theme =
    """
.{containerClass} {
    width: {containerWidth}em;
    height: {containerHeight}em;
    display: flex;
    justify-content: center;
    align-items: center;
}
.{wholeCubeClass} {
    width: {wholeCubeSideLength}em;
    height: {wholeCubeSideLength}em;
    transform-origin: center center -{halfCubeSideLength}em;
    transform-style: preserve-3d;
    transform: rotateY(-20deg) rotateX(-15deg) rotateZ(5deg);
    position: relative;
}
.{faceClass} {
    position: absolute;
    top: 0;
    left: 0;
    width: {cubieSideLength}em;
    height: {cubieSideLength}em;
    transform-origin: center center -{halfCubieSideLength}em;
    transform-style: preserve-3d;
    border: {plasticColor} solid {cubieBorderLength}em;
    box-sizing: border-box;
}
.{cubieClass} {
    position: absolute;
    top: 0;
    left: 0;
    width: {cubieSideLength}em;
    height: {cubieSideLength}em;
    transform-style: preserve-3d;
    transform-origin: center center -{halfCubieSideLength}em;
    display: inline-block;
}
.{upFaceClass} { transform: rotateX(90deg); }
.{downFaceClass} { transform: rotateX(-90deg); }
.{rightFaceClass} { transform: rotateY(90deg); }
.{leftFaceClass} { transform: rotateY(-90deg); }
.{frontFaceClass} { }
.{backFaceClass} { transform: rotateY(180deg); }
.{upColorClass} { background-color: {upColor} }
.{downColorClass} { background-color: {downColor} }
.{frontColorClass} { background-color: {frontColor} }
.{backColorClass} { background-color: {backColor} }
.{leftColorClass} { background-color: {leftColor} }
.{rightColorClass} { background-color: {rightColor} }
.{plasticColorClass} { background-color: {plasticColor} }
"""
        |> String.replace "{containerClass}" classes.container
        |> String.replace "{wholeCubeClass}" classes.wholeCube
        |> String.replace "{cubieClass}" classes.cubie
        |> String.replace "{faceClass}" classes.face
        |> String.replace "{upFaceClass}" classes.upFace
        |> String.replace "{downFaceClass}" classes.downFace
        |> String.replace "{rightFaceClass}" classes.rightFace
        |> String.replace "{leftFaceClass}" classes.leftFace
        |> String.replace "{frontFaceClass}" classes.frontFace
        |> String.replace "{backFaceClass}" classes.backFace
        |> String.replace "{upColorClass}" classes.upColor
        |> String.replace "{downColorClass}" classes.downColor
        |> String.replace "{frontColorClass}" classes.frontColor
        |> String.replace "{backColorClass}" classes.backColor
        |> String.replace "{leftColorClass}" classes.leftColor
        |> String.replace "{rightColorClass}" classes.rightColor
        |> String.replace "{plasticColorClass}" classes.plasticColor
        |> String.replace "{upColor}" theme.up
        |> String.replace "{downColor}" theme.down
        |> String.replace "{rightColor}" theme.right
        |> String.replace "{leftColor}" theme.left
        |> String.replace "{frontColor}" theme.front
        |> String.replace "{backColor}" theme.back
        |> String.replace "{plasticColor}" theme.plastic
        |> String.replace "{cubieSideLength}" (String.fromFloat cubieSideLength)
        |> String.replace "{halfCubieSideLength}" (String.fromFloat (cubieSideLength / 2))
        |> String.replace "{cubieBorderLength}" (String.fromFloat cubieBorderWidth)
        |> String.replace "{wholeCubeSideLength}" (String.fromFloat wholeCubeSideLength)
        |> String.replace "{halfCubeSideLength}" (String.fromFloat (wholeCubeSideLength / 2))
        |> String.replace "{containerWidth}" (String.fromFloat (wholeCubeSideLength * 1.4))
        |> String.replace "{containerHeight}" (String.fromFloat (wholeCubeSideLength * 1.4))


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


type alias Classes =
    { container : String
    , wholeCube : String
    , cubie : String
    , face : String
    , upFace : String
    , downFace : String
    , rightFace : String
    , leftFace : String
    , frontFace : String
    , backFace : String
    , upColor : String
    , downColor : String
    , frontColor : String
    , backColor : String
    , leftColor : String
    , rightColor : String
    , plasticColor : String
    }


classes : Classes
classes =
    { -- Suffix there is for unicity
      container = "cube-container" ++ randomSuffix
    , wholeCube = "cube" ++ randomSuffix
    , cubie = "cubie" ++ randomSuffix
    , face = "face" ++ randomSuffix
    , upFace = "up" ++ randomSuffix
    , downFace = "down" ++ randomSuffix
    , rightFace = "right" ++ randomSuffix
    , leftFace = "left" ++ randomSuffix
    , frontFace = "front" ++ randomSuffix
    , backFace = "back" ++ randomSuffix
    , upColor = "u" ++ randomSuffix
    , downColor = "d" ++ randomSuffix
    , frontColor = "f" ++ randomSuffix
    , backColor = "b" ++ randomSuffix
    , leftColor = "l" ++ randomSuffix
    , rightColor = "r" ++ randomSuffix
    , plasticColor = "p" ++ randomSuffix
    }


randomSuffix : String
randomSuffix =
    let
        generator =
            Random.map (String.join "" << List.map String.fromInt) <|
                Random.list 5 <|
                    Random.int 0 9

        seed =
            -- Just the JS timestamp of when this code was written
            Random.initialSeed 1616666856715
    in
    Tuple.first <| Random.step generator seed


getColorClass : Cube.Face -> Cube.CubieRendering -> String
getColorClass face rendering =
    let
        color =
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

        class =
            case color of
                Cube.UpColor ->
                    classes.upColor

                Cube.DownColor ->
                    classes.downColor

                Cube.FrontColor ->
                    classes.frontColor

                Cube.BackColor ->
                    classes.backColor

                Cube.LeftColor ->
                    classes.leftColor

                Cube.RightColor ->
                    classes.rightColor

                Cube.PlasticColor ->
                    classes.plasticColor
    in
    class
