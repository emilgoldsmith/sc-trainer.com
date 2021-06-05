module PLLTrainer.TestCase exposing (AUF(..), TestCase, build, generate, pll, postAuf, preAuf, toAlg)

import Algorithm exposing (Algorithm)
import List.Nonempty
import PLL exposing (PLL)
import Random


type TestCase
    = TestCase ( Algorithm, PLL, Algorithm )


type AUF
    = U
    | U2
    | NoAUF
    | UPrime


build : AUF -> PLL -> AUF -> TestCase
build preauf pll_ postauf =
    TestCase ( aufToAlgorithm preauf, pll_, aufToAlgorithm postauf )


aufToAlgorithm : AUF -> Algorithm
aufToAlgorithm auf =
    case auf of
        NoAUF ->
            Algorithm.empty

        U ->
            Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]

        U2 ->
            Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise ]

        UPrime ->
            Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise ]


toAlg : TestCase -> Algorithm.Algorithm
toAlg (TestCase ( preauf, pll_, postauf )) =
    preauf
        |> Algorithm.append (PLL.getAlg pll_)
        |> Algorithm.append postauf


generate : Random.Generator TestCase
generate =
    Random.map TestCase <|
        Random.map3 (\a b c -> ( a, b, c ))
            (List.Nonempty.sample Algorithm.aufs)
            (List.Nonempty.sample PLL.allPlls)
            (List.Nonempty.sample Algorithm.aufs)


preAuf : TestCase -> Algorithm
preAuf (TestCase ( x, _, _ )) =
    x


pll : TestCase -> PLL
pll (TestCase ( _, x, _ )) =
    x


postAuf : TestCase -> Algorithm
postAuf (TestCase ( _, _, x )) =
    x
