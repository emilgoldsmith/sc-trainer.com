module Components.Cube exposing (viewUBL, viewUFR)

import Element
import Html exposing (..)
import Html.Attributes exposing (..)
import Models.Cube as Cube
import Utils.Css exposing (htmlTestid)



-- Exports


viewUFR : Int -> Cube.Cube -> Element.Element msg
viewUFR =
    getCubeHtml ufrRotation


viewUBL : Int -> Cube.Cube -> Element.Element msg
viewUBL =
    getCubeHtml <| ufrRotation ++ [ YDegrees 180 ]



-- PARAMETERS


ufrRotation : List AxisRotation
ufrRotation =
    [ YDegrees -20, XDegrees -15, ZDegrees 5 ]


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


containerRatio : Float
containerRatio =
    1


wholeCubeSideLengthRatio : Float
wholeCubeSideLengthRatio =
    containerRatio / 1.4


cubieSideLengthRatio : Float
cubieSideLengthRatio =
    wholeCubeSideLengthRatio / 3


cubieBorderWidthRatio : Float
cubieBorderWidthRatio =
    cubieSideLengthRatio / 10



-- HTML


type alias Size =
    Int


getCubeHtml : CubeRotation -> Size -> Cube.Cube -> Element.Element msg
getCubeHtml rotation size cube =
    Element.html <|
        let
            rendering =
                Cube.render cube
        in
        div
            [ htmlTestid "cube"
            , style "width" (getContainerSize identity size)
            , style "height" (getContainerSize identity size)
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            ]
            [ div
                [ style "width" (getWholeCubeSideLength identity size)
                , style "height" (getWholeCubeSideLength identity size)
                , style "position" "relative"
                , style "transform-origin" ("center center -" ++ getWholeCubeSideLength (\x -> x / 2) size)
                , style "transform-style" "preserve-3d"
                , toTransformCSS rotation
                ]
              <|
                List.map (\( a, b, c ) -> displayCubie defaultTheme size b c a)
                    (getRenderedCorners rendering ++ getRenderedEdges rendering ++ getRenderedCenters rendering)
            ]


displayCubie : CubeTheme -> Size -> Coordinates -> TextOnFaces -> Cube.CubieRendering -> Html msg
displayCubie theme size { fromFront, fromLeft, fromTop } textOnFaces rendering =
    div
        [ style "position" "absolute"
        , style "width" (getCubieSideLength identity size)
        , style "height" (getCubieSideLength identity size)
        , style "transform-origin" ("center center -" ++ getCubieSideLength (\x -> x / 2) size)
        , style "transform-style" "preserve-3d"
        , style "display" "inline-block"

        -- Position the cubie correctly
        , style "top" (getCubieSideLength ((*) fromTop) size)
        , style "left" (getCubieSideLength ((*) fromLeft) size)
        , style "transform" ("translateZ(" ++ getCubieSideLength ((*) (fromFront * -1)) size ++ ")")
        ]
        (List.map (\face -> displayCubieFace theme size face (getTextForFace textOnFaces face) rendering) Cube.faces)


displayCubieFace : CubeTheme -> Size -> Cube.Face -> Maybe String -> Cube.CubieRendering -> Html msg
displayCubieFace theme size face textOnFace rendering =
    div
        [ style "transform" <| (face |> getFaceRotation |> toCssRotationString)
        , style "background-color" <| getColorString theme (getFaceColor face rendering)
        , style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
        , style "width" (getCubieSideLength identity size)
        , style "height" (getCubieSideLength identity size)

        -- Notice the negative sign here
        , style "transform-origin" ("center center -" ++ getCubieSideLength (\x -> x / 2) size)
        , style "transform-style" "preserve-3d"
        , style "border" (theme.plastic ++ " solid " ++ getCubieBorderWidth identity size)
        , style "box-sizing" "border-box"
        ]
    <|
        (textOnFace
            |> Maybe.map
                (\actualTextOnFace ->
                    [ div
                        [ style "font-size" "35px"
                        , style "display" "flex"
                        , style "justify-content" "center"
                        , style "align-items" "center"
                        , style "width" "100%"
                        , style "height" "100%"
                        ]
                        [ text actualTextOnFace ]
                    ]
                )
            |> Maybe.withDefault []
        )



-- LOGIC AND MAPPINGS


getContainerSize : (Float -> Float) -> Int -> String
getContainerSize fn =
    computePixelSize (fn containerRatio)


getWholeCubeSideLength : (Float -> Float) -> Int -> String
getWholeCubeSideLength fn =
    computePixelSize (fn wholeCubeSideLengthRatio)


getCubieSideLength : (Float -> Float) -> Int -> String
getCubieSideLength fn =
    computePixelSize (fn cubieSideLengthRatio)


getCubieBorderWidth : (Float -> Float) -> Int -> String
getCubieBorderWidth fn =
    computePixelSize (fn cubieBorderWidthRatio)


computePixelSize : Float -> Int -> String
computePixelSize ratio size =
    let
        pixels =
            toFloat size * ratio |> round
    in
    String.fromInt pixels ++ "px"


getTextForFace : TextOnFaces -> Cube.Face -> Maybe String
getTextForFace textOnFaces face =
    case face of
        Cube.UpOrDown Cube.U ->
            textOnFaces.u

        Cube.UpOrDown Cube.D ->
            textOnFaces.d

        Cube.FrontOrBack Cube.F ->
            textOnFaces.f

        Cube.FrontOrBack Cube.B ->
            textOnFaces.b

        Cube.LeftOrRight Cube.L ->
            textOnFaces.l

        Cube.LeftOrRight Cube.R ->
            textOnFaces.r


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
    List AxisRotation


getRenderedCorners : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates, TextOnFaces )
getRenderedCorners rendering =
    List.map (getRenderedCorner rendering) Cube.cornerLocations


getRenderedCorner : Cube.Rendering -> Cube.CornerLocation -> ( Cube.CubieRendering, Coordinates, TextOnFaces )
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
    ( cornerRendering, getCornerCoordinates location, noText )


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


type alias TextOnFaces =
    { u : Maybe String
    , d : Maybe String
    , f : Maybe String
    , b : Maybe String
    , l : Maybe String
    , r : Maybe String
    }


noText =
    { u = Nothing
    , d = Nothing
    , f = Nothing
    , b = Nothing
    , l = Nothing
    , r = Nothing
    }


getRenderedEdges : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates, TextOnFaces )
getRenderedEdges rendering =
    List.map (getRenderedEdge rendering) Cube.edgeLocations


getRenderedEdge : Cube.Rendering -> Cube.EdgeLocation -> ( Cube.CubieRendering, Coordinates, TextOnFaces )
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
    ( edgeRendering, getEdgeCoordinates location, noText )


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


getRenderedCenters : Cube.Rendering -> List ( Cube.CubieRendering, Coordinates, TextOnFaces )
getRenderedCenters rendering =
    List.map (getRenderedCenter rendering) Cube.centerLocations


getRenderedCenter : Cube.Rendering -> Cube.CenterLocation -> ( Cube.CubieRendering, Coordinates, TextOnFaces )
getRenderedCenter rendering location =
    let
        ( centerRendering, textOnFace ) =
            case location of
                Cube.CenterLocation (Cube.UpOrDown Cube.U) ->
                    ( rendering.u, { noText | u = Just "U" } )

                Cube.CenterLocation (Cube.UpOrDown Cube.D) ->
                    ( rendering.d, { noText | d = Just "D" } )

                Cube.CenterLocation (Cube.LeftOrRight Cube.L) ->
                    ( rendering.l, { noText | l = Just "L" } )

                Cube.CenterLocation (Cube.LeftOrRight Cube.R) ->
                    ( rendering.r, { noText | r = Just "R" } )

                Cube.CenterLocation (Cube.FrontOrBack Cube.F) ->
                    ( rendering.f, { noText | f = Just "F" } )

                Cube.CenterLocation (Cube.FrontOrBack Cube.B) ->
                    ( rendering.b, { noText | b = Just "B" } )
    in
    ( centerRendering, getCenterCoordinates location, textOnFace )


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
