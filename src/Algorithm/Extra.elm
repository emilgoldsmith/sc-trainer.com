module Algorithm.Extra exposing (complexity, complexityAdjustedTPS)

import Algorithm exposing (Algorithm)


complexityAdjustedTPS : { milliseconds : Float } -> Algorithm -> Float
complexityAdjustedTPS { milliseconds } algorithm =
    let
        seconds =
            milliseconds / 1000
    in
    complexity algorithm / seconds


complexity : Algorithm -> Float
complexity algorithm =
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
