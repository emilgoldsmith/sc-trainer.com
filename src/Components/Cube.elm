module Components.Cube exposing (injectStyles, viewUBL, viewUFR)

import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Algorithm as Algorithm
import Models.Cube as Cube
import Random
import Utils.Css exposing (htmlTestid)



-- Exports


viewUFR : Int -> Cube.Cube -> Element.Element msg
viewUFR cubeSize cube =
    Element.html <|
        let
            rendering =
                Cube.render cube
        in
        div [ class classes.container, htmlTestid "cube", style "font-size" <| String.fromInt cubeSize ++ "px" ]
            [ div
                [ style "width" (String.fromFloat wholeCubeSideLength ++ "em")
                , style "height" (String.fromFloat wholeCubeSideLength ++ "em")
                , style "position" "relative"
                , style "transform-origin" ("center center -" ++ String.fromFloat (wholeCubeSideLength / 2) ++ "em")
                , style "transform-style" "preserve-3d"
                , style "transform" "rotateY(-20deg) rotateX(-15deg) rotateZ(5deg)"
                ]
              <|
                List.map (\( a, b ) -> displayCubie defaultTheme b a)
                    (getRenderedCorners rendering ++ getRenderedEdges rendering ++ getRenderedCenters rendering)
            ]


viewUBL : Int -> Cube.Cube -> Element.Element msg
viewUBL cubeSize cube =
    let
        rotatedCube =
            Cube.applyAlgorithm
                (Algorithm.build [ Algorithm.Turn Algorithm.Y Algorithm.Halfway Algorithm.Clockwise ])
                cube
    in
    viewUFR cubeSize rotatedCube


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
    let
        ( faceColor, facePositionStyling ) =
            Tuple.mapSecond (style "transform") <|
                case face of
                    Cube.UpOrDown Cube.U ->
                        ( rendering.u, "rotateX(90deg)" )

                    Cube.UpOrDown Cube.D ->
                        ( rendering.d, "rotateX(-90deg)" )

                    Cube.FrontOrBack Cube.F ->
                        ( rendering.f, "" )

                    Cube.FrontOrBack Cube.B ->
                        ( rendering.b, "rotateY(180deg)" )

                    Cube.LeftOrRight Cube.L ->
                        ( rendering.l, "rotateY(-90deg)" )

                    Cube.LeftOrRight Cube.R ->
                        ( rendering.r, "rotateY(90deg)" )

        colorStyling =
            style "background-color" <|
                case faceColor of
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
    in
    div
        [ facePositionStyling
        , colorStyling
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
css _ =
    """
.{containerClass} {
    width: {containerWidth}em;
    height: {containerHeight}em;
    display: flex;
    justify-content: center;
    align-items: center;
}
"""
        |> String.replace "{containerClass}" classes.container
        |> String.replace "{containerWidth}" (String.fromFloat cubeContainerSize)
        |> String.replace "{containerHeight}" (String.fromFloat cubeContainerSize)


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
    }


classes : Classes
classes =
    { -- Suffix there is for unicity
      container = "cube-container" ++ randomSuffix
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
