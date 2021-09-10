module Tests.PLLTrainer.TestCase exposing (toAlgTests)

import AUF
import Algorithm
import Expect
import Fuzz.Extra
import PLL
import PLLTrainer.TestCase
import Test exposing (..)
import User


toAlgTests : Test
toAlgTests =
    describe "toAlg"
        [ fuzz3 Fuzz.Extra.algorithm Fuzz.Extra.auf Fuzz.Extra.auf "simple ordering test" <|
            \algorithm preAUF postAUF ->
                let
                    testCase =
                        PLLTrainer.TestCase.build preAUF PLL.Gc postAUF

                    user =
                        User.changePLLAlgorithm PLL.Gc algorithm User.new
                in
                PLLTrainer.TestCase.toAlg user testCase
                    |> Expect.equal
                        (Algorithm.fromTurnList <|
                            (AUF.toAlgorithm >> Algorithm.toTurnList) preAUF
                                ++ Algorithm.toTurnList algorithm
                                ++ (AUF.toAlgorithm >> Algorithm.toTurnList) postAUF
                        )
        ]
