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
        [ fuzz3 Fuzz.bool Fuzz.Extra.pll (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf) "adds the aufs correctly from the correct pll when user has pll picked" <|
            \addFinalReorientationToAlgorithm pll ( preAUF, postAUF ) ->
                let
                    algorithm : Algorithm.Algorithm
                    algorithm =
                        PLL.getAlgorithm PLL.referenceAlgorithms pll

                    testCase : PLLTrainer.TestCase.TestCase
                    testCase =
                        PLLTrainer.TestCase.escapeHatch ( preAUF, pll, postAUF )

                    user : User.User
                    user =
                        User.changePLLAlgorithm pll algorithm User.new

                    result : Algorithm.Algorithm
                    result =
                        PLLTrainer.TestCase.toAlg { addFinalReorientationToAlgorithm = addFinalReorientationToAlgorithm } user testCase

                    expected : Algorithm.Algorithm
                    expected =
                        Cube.addAUFsToAlgorithm ( preAUF, postAUF ) algorithm
                in
                Cube.algorithmResultsAreEquivalentIndependentOfFinalRotation
                    result
                    expected
                    |> Expect.equal True
                    |> Expect.onFail ("the algorithms should be equivalent\nExpected: " ++ Debug.toString expected ++ "\nResult: " ++ Debug.toString result)
        , fuzz3 Fuzz.bool
            Fuzz.Extra.pll
            (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf)
            "adds the aufs correctly from the correct pll when user has not yet picked a pll"
          <|
            \addFinalReorientationToAlgorithm pll ( preAUF, postAUF ) ->
                let
                    testCase : PLLTrainer.TestCase.TestCase
                    testCase =
                        PLLTrainer.TestCase.escapeHatch ( preAUF, pll, postAUF )

                    algorithmWithoutAUFs : Algorithm.Algorithm
                    algorithmWithoutAUFs =
                        PLLTrainer.TestCase.escapeHatch ( AUF.None, pll, AUF.None )
                            |> PLLTrainer.TestCase.toAlg
                                { addFinalReorientationToAlgorithm = addFinalReorientationToAlgorithm }
                                User.new
                in
                PLLTrainer.TestCase.toAlg
                    { addFinalReorientationToAlgorithm = addFinalReorientationToAlgorithm }
                    User.new
                    testCase
                    |> Cube.algorithmResultsAreEquivalent
                        (Algorithm.fromTurnList <|
                            (AUF.toAlgorithm >> Algorithm.toTurnList) preAUF
                                ++ Algorithm.toTurnList algorithmWithoutAUFs
                                ++ (AUF.toAlgorithm >> Algorithm.toTurnList) postAUF
                        )
                    |> Expect.equal True
                    |> Expect.onFail "the algorithms should be equivalent"
        , test "simply retrieves the users algorithm when not adding final reorientation" <|
            \_ ->
                let
                    pll : PLL.PLL
                    pll =
                        PLL.Aa

                    algorithm : Algorithm.Algorithm
                    algorithm =
                        -- This is an algorithm that doesn't end in the starting orientation
                        Algorithm.fromString "l' U R' D2 R U' R' D2 R2"
                            |> Result.withDefault Algorithm.empty

                    user : User.User
                    user =
                        User.changePLLAlgorithm pll algorithm User.new

                    testCase : PLLTrainer.TestCase.TestCase
                    testCase =
                        PLLTrainer.TestCase.escapeHatch ( AUF.None, pll, AUF.None )
                in
                PLLTrainer.TestCase.toAlg { addFinalReorientationToAlgorithm = False } user testCase
                    |> Expect.equal algorithm
        , test "ends in starting orientation when setting the add final reorientation flag" <|
            \_ ->
                let
                    pll : PLL.PLL
                    pll =
                        PLL.Aa

                    notEndInStartOrientation : Algorithm.Algorithm
                    notEndInStartOrientation =
                        Algorithm.fromString "l' U R' D2 R U' R' D2 R2"
                            |> Result.withDefault Algorithm.empty

                    doesEndInStartOrientation : Algorithm.Algorithm
                    doesEndInStartOrientation =
                        Algorithm.fromString "l' U R' D2 R U' R' D2 R2 x'"
                            |> Result.withDefault Algorithm.empty

                    user : User.User
                    user =
                        User.changePLLAlgorithm pll notEndInStartOrientation User.new

                    testCase : PLLTrainer.TestCase.TestCase
                    testCase =
                        PLLTrainer.TestCase.escapeHatch ( AUF.None, pll, AUF.None )
                in
                PLLTrainer.TestCase.toAlg { addFinalReorientationToAlgorithm = True } user testCase
                    |> Cube.algorithmResultsAreEquivalent doesEndInStartOrientation
                    |> Expect.equal True
                    |> Expect.onFail "should be equivalent to an Aa algorithm ending in starting orientation"
        ]


generateTests : Test
generateTests =
    describe "generate"
        [ test "A new user gets a new case" <|
            \_ ->
                case
                    PLLTrainer.TestCase.generate
                        { now = Time.millisToPosix 0
                        , overrideWithConstantValue = Nothing
                        }
                        User.new
                of
                    Ok generatedCase ->
                        generatedCase
                            |> PLLTrainer.TestCase.isNewCaseGenerator
                            |> Expect.equal True
                            |> Expect.onFail "it wasn't a new case"

                    Err _ ->
                        Expect.fail "generatedCase returned an err"
        , fuzz3
            Fuzz.Extra.auf
            Fuzz.Extra.pll
            Fuzz.Extra.auf
            "To a new user all cases are new cases"
          <|
            \preAUF pll postAUF ->
                case
                    PLLTrainer.TestCase.generate
                        { now = Time.millisToPosix 0
                        , overrideWithConstantValue = Just <| PLLTrainer.TestCase.escapeHatch ( preAUF, pll, postAUF )
                        }
                        User.new
                of
                    Ok generatedCase ->
                        generatedCase
                            |> PLLTrainer.TestCase.isNewCaseGenerator
                            |> Expect.equal True
                            |> Expect.onFail "it wasn't a new case"

                    Err _ ->
                        Expect.fail "generatedCase returned an err"
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
                            (\user ->
                                case
                                    PLLTrainer.TestCase.generate
                                        { now = Time.millisToPosix 0
                                        , overrideWithConstantValue = Just <| PLLTrainer.TestCase.escapeHatch ( preAUF, pll, postAUF )
                                        }
                                        user
                                of
                                    Ok generatedCase ->
                                        generatedCase
                                            |> PLLTrainer.TestCase.isNewCaseGenerator
                                            |> Expect.equal False
                                            |> Expect.onFail "it was unexpectedly a new case"

                                    Err _ ->
                                        Expect.fail "generatedCase returned an err"
                            )
                        |> Result.withDefault (Expect.fail "a record pll test result call failed")
        ]
