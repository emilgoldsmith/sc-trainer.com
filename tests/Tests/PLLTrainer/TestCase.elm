module Tests.PLLTrainer.TestCase exposing (toAlgTests)

import AUF
import Algorithm
import Cube
import Expect
import Fuzz
import Fuzz.Extra
import PLL
import PLLTrainer.TestCase
import Test exposing (..)
import User


toAlgTests : Test
toAlgTests =
    describe "toAlg"
        [ fuzz2 Fuzz.Extra.pll (Fuzz.tuple ( Fuzz.Extra.auf, Fuzz.Extra.auf )) "adds the aufs correctly from the correct pll when user has pll picked" <|
            \pll ( preAUF, postAUF ) ->
                let
                    algorithm =
                        PLL.getAlgorithm PLL.referenceAlgorithms pll

                    testCase =
                        PLLTrainer.TestCase.build preAUF pll postAUF

                    user =
                        User.changePLLAlgorithm pll algorithm User.new

                    result =
                        PLLTrainer.TestCase.toAlg user testCase

                    expected =
                        AUF.addToAlgorithm ( preAUF, postAUF ) <|
                            Cube.makeAlgorithmMaintainOrientation
                                algorithm
                in
                Cube.algorithmResultsAreEquivalent
                    result
                    expected
                    |> Expect.true ("the algorithms should be equivalent\nExpected: " ++ Debug.toString expected ++ "\nResult: " ++ Debug.toString result)
        , fuzz2 Fuzz.Extra.pll (Fuzz.tuple ( Fuzz.Extra.auf, Fuzz.Extra.auf )) "adds the aufs correctly from the correct pll when user has not yet picked a pll" <|
            \pll ( preAUF, postAUF ) ->
                let
                    testCase =
                        PLLTrainer.TestCase.build preAUF pll postAUF

                    algorithmWithoutAUFs =
                        PLLTrainer.TestCase.build AUF.None pll AUF.None
                            |> PLLTrainer.TestCase.toAlg User.new
                in
                PLLTrainer.TestCase.toAlg User.new testCase
                    |> Cube.algorithmResultsAreEquivalent
                        (Algorithm.fromTurnList <|
                            (AUF.toAlgorithm >> Algorithm.toTurnList) preAUF
                                ++ Algorithm.toTurnList algorithmWithoutAUFs
                                ++ (AUF.toAlgorithm >> Algorithm.toTurnList) postAUF
                        )
                    |> Expect.true "the algorithms should be equivalent"
        ]
