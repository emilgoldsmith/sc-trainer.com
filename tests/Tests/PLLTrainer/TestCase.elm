module Tests.PLLTrainer.TestCase exposing (generateTests, toAlgTests)

import AUF
import Algorithm
import Cube
import Expect
import Fuzz
import Fuzz.Extra
import PLL
import PLLTrainer.TestCase
import Test exposing (..)
import Tests.User
import Time
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
                        Cube.addAUFsToAlgorithm ( preAUF, postAUF ) algorithm
                in
                Cube.algorithmResultsAreEquivalentIndependentOfFinalRotation
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


generateTests : Test
generateTests =
    describe "generate"
        [ test "A new user gets a new case" <|
            \_ ->
                User.new
                    |> PLLTrainer.TestCase.generate
                        { now = Time.millisToPosix 0
                        , overrideWithConstantValue = Nothing
                        }
                    |> PLLTrainer.TestCase.isNewCaseGenerator
                    |> Expect.true "it wasn't a new case"
        , fuzz3
            Fuzz.Extra.auf
            Fuzz.Extra.pll
            Fuzz.Extra.auf
            "To a new user all cases are new cases"
          <|
            \preAUF pll postAUF ->
                User.new
                    |> PLLTrainer.TestCase.generate
                        { now = Time.millisToPosix 0
                        , overrideWithConstantValue = Just <| PLLTrainer.TestCase.build preAUF pll postAUF
                        }
                    |> PLLTrainer.TestCase.isNewCaseGenerator
                    |> Expect.true "it wasn't a new case"
        , fuzz3
            Fuzz.Extra.auf
            Fuzz.Extra.pll
            Fuzz.Extra.auf
            "if both pre and post AUF have been encountered in different cases it's not a new case"
          <|
            \preAUF pll postAUF ->
                -- Don't bother with the symmetric PLLs as they have equivalent
                -- AUFs that make the test hard to write well as a fuzz test.
                -- Feel free to improve it if you have a good idea so we don't need this
                if List.member pll [ PLL.H, PLL.E, PLL.Z, PLL.Na, PLL.Nb ] then
                    Expect.pass

                else
                    User.new
                        |> User.changePLLAlgorithm pll Algorithm.empty
                        -- We use the AUF.add here to ensure that it's exactly a different pre and post auf that is used
                        -- so all three cases we are checking here are ensured to be unique
                        |> User.recordPLLTestResult pll (Tests.User.correctResult 500 ( preAUF, AUF.add postAUF AUF.Clockwise ))
                        |> Result.andThen
                            (User.recordPLLTestResult pll (Tests.User.correctResult 500 ( AUF.add preAUF AUF.Clockwise, postAUF )))
                        |> Result.map
                            (PLLTrainer.TestCase.generate
                                { now = Time.millisToPosix 0
                                , overrideWithConstantValue = Just <| PLLTrainer.TestCase.build preAUF pll postAUF
                                }
                            )
                        |> Result.map PLLTrainer.TestCase.isNewCaseGenerator
                        |> Result.map (Expect.false "it was unexpectedly a new case")
                        |> Result.withDefault (Expect.fail "a record pll test result call failed")
        ]
