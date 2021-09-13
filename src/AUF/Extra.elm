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
    in
    case matches of
        [] ->
            Err NoAUFsMakeThemMatch

        x :: _ ->
            Ok x
