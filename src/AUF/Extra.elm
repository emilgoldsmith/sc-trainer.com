module AUF.Extra exposing (DetectAUFsError(..), detectAUFs)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Cube
import List.Nonempty


type DetectAUFsError
    = NoAUFsMakeThemMatch


detectAUFs : { toMatchTo : Algorithm, toDetectFor : Algorithm } -> Result DetectAUFsError ( AUF, AUF )
detectAUFs { toMatchTo, toDetectFor } =
    let
        allAUFPairs =
            List.Nonempty.concatMap
                (\preAUF ->
                    List.Nonempty.map
                        (Tuple.pair preAUF)
                        AUF.all
                )
                AUF.all
                |> List.Nonempty.toList

        matches =
            List.filter
                (\aufs ->
                    Cube.algorithmResultsAreEquivalentIndependentOfFinalRotation
                        toMatchTo
                        (AUF.addToAlgorithm aufs toDetectFor)
                )
                allAUFPairs
                |> List.sortWith
                    (\a b ->
                        let
                            turnCountOrder =
                                -- Better the lower turn count
                                compare (countAUFTurns a) (countAUFTurns b)

                            numPreAUFsOrder =
                                -- Better the less pre aufs
                                compare (countPreAUFs a) (countPreAUFs b)

                            numCounterClockwisesOrder =
                                -- Better the less counter clockwise turns
                                compare (countCounterClockwises a) (countCounterClockwises b)

                            specialCaseOrder =
                                -- Just to be fully determined we prefer [U, U'] over [U', U]
                                compare (countCounterClockwiseBeforeClockwise a) (countCounterClockwiseBeforeClockwise b)
                        in
                        [ turnCountOrder, numPreAUFsOrder, numCounterClockwisesOrder, specialCaseOrder ]
                            -- Just pick the first one that's not EQ
                            |> List.filter ((/=) EQ)
                            |> List.head
                            |> Maybe.withDefault EQ
                    )
    in
    case matches of
        [] ->
            Err NoAUFsMakeThemMatch

        x :: _ ->
            Ok x


countAUFTurns : ( AUF, AUF ) -> Float
countAUFTurns ( preAUF, postAUF ) =
    countSingleAUFTurns preAUF + countSingleAUFTurns postAUF


countPreAUFs : ( AUF, AUF ) -> Float
countPreAUFs ( preAUF, _ ) =
    countSingleAUFTurns preAUF


countSingleAUFTurns : AUF -> Float
countSingleAUFTurns auf =
    case auf of
        AUF.None ->
            0

        -- Just anything between 1 and 1.5 really will do the trick for this usecase
        -- as it will never add a full 1 with two numbers added together but be more than a quarter turn
        AUF.Halfway ->
            1.2

        _ ->
            1


countCounterClockwises : ( AUF, AUF ) -> Int
countCounterClockwises ( preAUF, postAUF ) =
    (if preAUF == AUF.CounterClockwise then
        1

     else
        0
    )
        + (if postAUF == AUF.CounterClockwise then
            1

           else
            0
          )


countCounterClockwiseBeforeClockwise : ( AUF, AUF ) -> Int
countCounterClockwiseBeforeClockwise aufs =
    if aufs == ( AUF.CounterClockwise, AUF.Clockwise ) then
        1

    else
        0
