module PLLTrainer.TestCase exposing (TestCase, build, generate, pll, postAuf, preAuf, toAlg, toCube)

import AUF exposing (AUF)
import Algorithm
import Cube exposing (Cube)
import List.Nonempty
import PLL exposing (PLL)
import Random


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : AUF -> PLL -> AUF -> TestCase
build preauf pll_ postauf =
    TestCase ( preauf, pll_, postauf )


toAlg : TestCase -> Algorithm.Algorithm
toAlg (TestCase ( preauf, pll_, postauf )) =
    AUF.toAlgorithm preauf
        |> Algorithm.append (PLL.getAlgorithm PLL.referenceAlgorithms pll_)
        |> Algorithm.append (AUF.toAlgorithm postauf)


{-| A cube that would be solved by this test case
-}
toCube : TestCase -> Cube
toCube testCase =
    Cube.solved
        |> Cube.applyAlgorithm (Algorithm.inverse <| toAlg testCase)


generate : Random.Generator TestCase
generate =
    Random.map TestCase <|
        Random.map3 (\a b c -> ( a, b, c ))
            (List.Nonempty.sample AUF.all)
            (List.Nonempty.sample PLL.all)
            (List.Nonempty.sample AUF.all)


preAuf : TestCase -> AUF
preAuf (TestCase ( x, _, _ )) =
    x


pll : TestCase -> PLL
pll (TestCase ( _, x, _ )) =
    x


postAuf : TestCase -> AUF
postAuf (TestCase ( _, _, x )) =
    x
