module Algorithm.Extra exposing (complexityAdjustedTPS)

import Algorithm exposing (Algorithm)


complexityAdjustedTPS : { milliseconds : Float } -> Algorithm -> Float
complexityAdjustedTPS { milliseconds } algorithm =
    let
        withYRotationsTrimmed =
            algorithm
                |> Algorithm.toTurnList
                |> dropWhile isYRotation
                |> List.reverse
                |> dropWhile isYRotation
                |> List.reverse
                |> Algorithm.fromTurnList

        algorithmLength =
            withYRotationsTrimmed
                |> Algorithm.toTurnList
                |> List.length

        seconds =
            milliseconds / 1000
    in
    toFloat algorithmLength / seconds


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
