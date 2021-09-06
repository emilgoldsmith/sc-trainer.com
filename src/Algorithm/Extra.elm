module Algorithm.Extra exposing (complexity, complexityAdjustedTPS)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)


complexityAdjustedTPS : { milliseconds : Int } -> ( AUF, AUF ) -> Algorithm -> Float
complexityAdjustedTPS { milliseconds } aufs algorithm =
    let
        seconds =
            toFloat milliseconds / 1000
    in
    complexity aufs algorithm / seconds


complexity : ( AUF, AUF ) -> Algorithm -> Float
complexity ( preAUF, postAUF ) algorithm =
    let
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
        |> Algorithm.append (AUF.toAlgorithm preAUF)
        |> Algorithm.reverseAppend (AUF.toAlgorithm postAUF)
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
