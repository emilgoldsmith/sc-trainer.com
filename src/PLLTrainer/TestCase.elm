module PLLTrainer.TestCase exposing (TestCase, build, generate, pll, postAUF, preAUF, toAlg, toCube)

import AUF exposing (AUF)
import AUF.Extra
import Algorithm
import Cube exposing (Cube)
import List.Nonempty
import PLL exposing (PLL)
import Random
import User exposing (User)


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : AUF -> PLL -> AUF -> TestCase
build preAUF_ pll_ postAUF_ =
    let
        -- Any pll algorithm will do. The equivalency classes of different
        -- AUFs for a PLL should be independent of the algorithm used and which
        -- AUFs/angles it uses
        pllAlgorithm =
            PLL.getAlgorithm PLL.referenceAlgorithms pll_

        ( optimizedPreAUF, optimizedPostAUF ) =
            AUF.Extra.detectAUFs
                { toMatchTo =
                    Algorithm.append
                        (AUF.toAlgorithm preAUF_)
                    <|
                        Algorithm.append (Cube.makeAlgorithmMaintainOrientation pllAlgorithm) <|
                            AUF.toAlgorithm postAUF_
                , toDetectFor = pllAlgorithm
                }
                -- This should never be an error but this is a sensible default in case
                -- it somehow does.
                |> Result.withDefault ( preAUF_, postAUF_ )
    in
    TestCase ( optimizedPreAUF, pll_, optimizedPostAUF )


toAlg : User -> TestCase -> Algorithm.Algorithm
toAlg user (TestCase ( preAUF_, pll_, postAUF_ )) =
    let
        baseAlgorithm =
            User.getPLLAlgorithm pll_ user
                |> Maybe.withDefault (PLL.getAlgorithm PLL.referenceAlgorithms pll_)
                |> Cube.makeAlgorithmMaintainOrientation
    in
    baseAlgorithm
        |> AUF.addToAlgorithm ( preAUF_, postAUF_ )


{-| A cube that would be solved by this test case
-}
toCube : User -> TestCase -> Cube
toCube user testCase =
    Cube.solved
        |> Cube.applyAlgorithm (Algorithm.inverse <| toAlg user testCase)


generate : Random.Generator TestCase
generate =
    Random.map TestCase <|
        Random.map3 (\a b c -> ( a, b, c ))
            (List.Nonempty.sample AUF.all)
            (List.Nonempty.sample PLL.all)
            (List.Nonempty.sample AUF.all)


preAUF : TestCase -> AUF
preAUF (TestCase ( x, _, _ )) =
    x


pll : TestCase -> PLL
pll (TestCase ( _, x, _ )) =
    x


postAUF : TestCase -> AUF
postAUF (TestCase ( _, _, x )) =
    x
