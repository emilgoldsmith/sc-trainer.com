module PLLTrainer.TestCase exposing (TestCase, generate, toAlg)

import Algorithm exposing (Algorithm)
import List.Nonempty
import PLL exposing (PLL)
import Random


type alias TestCase =
    ( Algorithm, PLL, Algorithm )


toAlg : TestCase -> Algorithm.Algorithm
toAlg ( preauf, pll, postauf ) =
    preauf
        |> Algorithm.append (PLL.getAlg pll)
        |> Algorithm.append postauf


generate : Random.Generator TestCase
generate =
    Random.map3 (\a b c -> ( a, b, c ))
        (List.Nonempty.sample Algorithm.aufs)
        (List.Nonempty.sample PLL.allPlls)
        (List.Nonempty.sample Algorithm.aufs)
