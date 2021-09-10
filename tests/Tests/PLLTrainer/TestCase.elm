module Tests.PLLTrainer.TestCase exposing (toAlgTests)

import AUF
import Algorithm
import Expect
import Fuzz
import Fuzz.Extra
import PLLTrainer.TestCase
import Test exposing (..)
import User


toAlgTests : Test
toAlgTests =
    describe "toAlg"
        [ fuzz3 Fuzz.Extra.pll Fuzz.Extra.algorithm (Fuzz.tuple ( Fuzz.Extra.auf, Fuzz.Extra.auf )) "adds the aufs correctly from the correct pll when user has pll picked" <|
            \pll algorithm ( preAUF, postAUF ) ->
                let
                    testCase =
                        PLLTrainer.TestCase.build preAUF pll postAUF

                    user =
                        User.changePLLAlgorithm pll algorithm User.new
                in
                PLLTrainer.TestCase.toAlg user testCase
                    |> Expect.equal
                        (Algorithm.fromTurnList <|
                            (AUF.toAlgorithm >> Algorithm.toTurnList) preAUF
                                ++ Algorithm.toTurnList algorithm
                                ++ (AUF.toAlgorithm >> Algorithm.toTurnList) postAUF
                        )
        , fuzz2 Fuzz.Extra.pll (Fuzz.tuple ( Fuzz.Extra.auf, Fuzz.Extra.auf )) "adds the aufs correctly from the correct pll when user has not yet picked a pll" <|
            \pll ( preAUF, postAUF ) ->
                let
                    testCase =
                        PLLTrainer.TestCase.build preAUF pll postAUF

                    testCaseWithNoAUFs =
                        PLLTrainer.TestCase.build AUF.None pll AUF.None

                    algorithmWithoutAUFs =
                        PLLTrainer.TestCase.toAlg User.new testCaseWithNoAUFs
                in
                PLLTrainer.TestCase.toAlg User.new testCase
                    |> Expect.equal
                        (Algorithm.fromTurnList <|
                            (AUF.toAlgorithm >> Algorithm.toTurnList) preAUF
                                ++ Algorithm.toTurnList algorithmWithoutAUFs
                                ++ (AUF.toAlgorithm >> Algorithm.toTurnList) postAUF
                        )
        ]
