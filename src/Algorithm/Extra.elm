module Algorithm.Extra exposing (TPSError(..), complexity, complexityAdjustedTPS)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Basics.Extra
import Cube


type TPSError
    = ZeroMillisecondsError


complexityAdjustedTPS : { milliseconds : Int } -> ( AUF, AUF ) -> Algorithm -> Result TPSError Float
complexityAdjustedTPS { milliseconds } aufs algorithm =
    let
        seconds : Float
        seconds =
            toFloat milliseconds / 1000
    in
    Basics.Extra.safeDivide
        (complexity aufs algorithm)
        seconds
        |> Result.fromMaybe ZeroMillisecondsError


complexity : ( AUF, AUF ) -> Algorithm -> Float
complexity aufs algorithm =
    let
        withYRotationsTrimmed : Algorithm
        withYRotationsTrimmed =
            algorithm
                |> Algorithm.toTurnList
                |> dropWhile isYRotation
                |> List.reverse
                |> dropWhile isYRotation
                |> List.reverse
                |> Algorithm.fromTurnList
    in
    withYRotationsTrimmed
        |> Cube.addAUFsToAlgorithm aufs
        |> Algorithm.toTurnList
        |> List.length
        |> toFloat


isYRotation : Algorithm.Turn -> Bool
isYRotation (Algorithm.Turn turnable _ _) =
    turnable == Algorithm.Y


dropWhile : (a -> Bool) -> List a -> List a
dropWhile fn list =
    case list of
        [] ->
            []

        x :: xs ->
            if fn x then
                dropWhile fn xs

            else
                list
