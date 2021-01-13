module Components.Cube exposing (injectStyles, view)

import Html exposing (..)
import Html.Attributes exposing (..)



-- Exports


view : Html Never
view =
    div [ style "top" "100px", style "left" "100px", style "position" "relative", style "transform" "rotate3d(1, 1, 1, 45deg)", style "transform-style" "preserve-3d", style "width" "2em", style "height" "2em" ] [ displayCubie ]


injectStyles : Html Never
injectStyles =
    styleTag [] [ text (css defaultTheme) ]



-- HTML


displayCubie : Html Never
displayCubie =
    div [ class classes.cubie ] (List.map displayCubieFace cubeFaces)


displayCubieFace : CubeFace -> Html Never
displayCubieFace cubeFace =
    div [ classList (getFaceClasses cubeFace) ] []


type CubeFace
    = U
    | D
    | R
    | L
    | F
    | B


getFaceClasses : CubeFace -> List ( String, Bool )
getFaceClasses cubeFace =
    let
        faceSpecifierClass =
            case cubeFace of
                U ->
                    classes.upFace

                D ->
                    classes.downFace

                R ->
                    classes.rightFace

                L ->
                    classes.leftFace

                F ->
                    classes.frontFace

                B ->
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
.{upFaceClass} { background-color: {upColor}; transform: rotateX(90deg); }
.{downFaceClass} { background-color: {downColor}; transform: rotateX(-90deg); }
.{rightFaceClass} { background-color: {rightColor}; transform: rotateY(90deg); }
.{leftFaceClass} { background-color: {leftColor}; transform: rotateY(-90deg); }
.{frontFaceClass} { background-color: {frontColor}; }
.{backFaceClass} { background-color: {backColor}; transform: rotateY(180deg); }
"""
        |> String.replace "{faceClass}" classes.face
        |> String.replace "{cubieClass}" classes.cubie
        |> String.replace "{upFaceClass}" classes.upFace
        |> String.replace "{downFaceClass}" classes.downFace
        |> String.replace "{rightFaceClass}" classes.rightFace
        |> String.replace "{leftFaceClass}" classes.leftFace
        |> String.replace "{frontFaceClass}" classes.frontFace
        |> String.replace "{backFaceClass}" classes.backFace
        |> String.replace "{upColor}" theme.up
        |> String.replace "{downColor}" theme.down
        |> String.replace "{rightColor}" theme.right
        |> String.replace "{leftColor}" theme.left
        |> String.replace "{frontColor}" theme.front
        |> String.replace "{backColor}" theme.back
        |> String.replace "{plasticColor}" theme.plastic
        |> String.replace "{cubieSideLength}" (String.fromFloat cubieSideLength)
        |> String.replace "{halfCubieSideLength}" (String.fromFloat halfCubieSideLength)
        |> String.replace "{cubieBorderLength}" (String.fromFloat cubieBorderWidth)


classes : { face : String, cubie : String, upFace : String, downFace : String, rightFace : String, leftFace : String, frontFace : String, backFace : String }
classes =
    { face = "face"
    , cubie = "cubie"
    , upFace = "up"
    , downFace = "down"
    , rightFace = "right"
    , leftFace = "left"
    , frontFace = "front"
    , backFace = "back"
    }


cubieSideLength : Float
cubieSideLength =
    2


halfCubieSideLength : Float
halfCubieSideLength =
    cubieSideLength / 2


cubieBorderWidth : Float
cubieBorderWidth =
    cubieSideLength / 10



-- Type enumerator
-- Taken from https://discourse.elm-lang.org/t/enumerate-function-for-non-infinite-custom-types-proposal/2636/7


type alias Order a =
    a -> Maybe a


enumerateFrom : a -> Order a -> List a
enumerateFrom previous toNext =
    case toNext previous of
        Just next ->
            next :: enumerateFrom next toNext

        Nothing ->
            []


fromU : Order CubeFace
fromU face =
    case face of
        U ->
            Just D

        D ->
            Just R

        R ->
            Just L

        L ->
            Just F

        F ->
            Just B

        B ->
            Nothing


cubeFaces : List CubeFace
cubeFaces =
    enumerateFrom U fromU
