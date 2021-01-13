module Models.Cube exposing (algFromString, applyAlgorithm, solved, view)

import Html exposing (..)


type UpOrDown
    = Up
    | Down


type FrontOrBack
    = Front
    | Back


type LeftOrRight
    = Left
    | Right


type Face
    = U
    | D
    | F
    | B
    | R
    | L


algFromString : String -> Result String Algorithm
algFromString s =
    Ok []


type alias Cube =
    ( CornerPositions, EdgePositions )


type alias CornerPositions =
    { ufr : OrientedCorner
    }


type alias EdgePositions =
    { uf : OrientedEdge
    }


type alias OrientedEdge =
    ( Edge, EdgeOrientation )


type alias OrientedCorner =
    ( Corner, CornerOrientation )


type Edge
    = UF
    | UB
    | UR


type Corner
    = UFR
    | UFL
    | UBR


solved : Cube
solved =
    ( { ufr = ( UFR, NotTwisted )
      }
    , { uf = ( UF, NotFlipped )
      }
    )


type alias Algorithm =
    List Move


type MoveDirection
    = Clockwise
    | CounterClockwise


type TurnNumber
    = One
    | Two
    | Three


type alias Move =
    ( Face, MoveDirection, TurnNumber )


applyAlgorithm : Algorithm -> Cube -> Cube
applyAlgorithm alg cube =
    List.foldl applyMove cube alg


type alias CornerFaceClockwiseOrder =
    { first : Corner, second : Corner, third : Corner, fourth : Corner }


type alias EdgeFaceClockwiseOrder =
    { first : Edge, second : Edge, third : Edge, fourth : Edge }



-- applyTurn : List Corner -> List Edge -> MoveDirection -> Cube -> Cube
-- applyTurn clockwiseCorners clockwiseEdge direction cube = case


applyMove : Move -> Cube -> Cube
applyMove move cube =
    case move of
        ( U, direction, turnNumber ) ->
            cube

        _ ->
            cube


type EdgeOrientation
    = NotFlipped
    | Flipped


type CornerOrientation
    = NotTwisted
    | TwistedClockwise
    | TwistedCounterClockwise


view : Html Never
view =
    text "Test"
