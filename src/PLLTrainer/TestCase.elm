module PLLTrainer.TestCase exposing (Generator, TestCase, build, generate, getGenerator, isNewCaseGenerator, pll, postAUF, preAUF, toAlg, toCube, toTriple)

import AUF exposing (AUF)
import Algorithm
import Cube exposing (Cube)
import List.Nonempty
import List.Nonempty.Extra
import PLL exposing (PLL)
import PLL.Extra
import Random
import Time
import User exposing (User)


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : AUF -> PLL -> AUF -> TestCase
build preAUF_ pll_ postAUF_ =
    let
        ( optimizedPreAUF, optimizedPostAUF ) =
            PLL.Extra.getPreferredEquivalentAUFs ( preAUF_, pll_, postAUF_ )
    in
    TestCase ( optimizedPreAUF, pll_, optimizedPostAUF )


toAlg : { addFinalReorientationToAlgorithm : Bool } -> User -> TestCase -> Algorithm.Algorithm
toAlg { addFinalReorientationToAlgorithm } user (TestCase ( preAUF_, pll_, postAUF_ )) =
    let
        baseAlgorithm =
            User.getPLLAlgorithm pll_ user
                |> Maybe.withDefault (PLL.getAlgorithm PLL.referenceAlgorithms pll_)
                |> (if addFinalReorientationToAlgorithm then
                        Cube.makeAlgorithmMaintainOrientation

                    else
                        identity
                   )
    in
    baseAlgorithm
        |> Cube.addAUFsToAlgorithm ( preAUF_, postAUF_ )


toTriple : TestCase -> ( AUF, PLL, AUF )
toTriple (TestCase triple) =
    triple


{-| A cube that would be solved by this test case
-}
toCube : User -> TestCase -> Cube
toCube user testCase =
    Cube.solved
        |> Cube.applyAlgorithm
            (Algorithm.inverse <|
                -- We want the final reorientation or we will display the cube in the wrong
                -- orientation
                toAlg { addFinalReorientationToAlgorithm = True } user testCase
            )


preAUF : TestCase -> AUF
preAUF (TestCase ( x, _, _ )) =
    x


pll : TestCase -> PLL
pll (TestCase ( _, x, _ )) =
    x


postAUF : TestCase -> AUF
postAUF (TestCase ( _, _, x )) =
    x


type Generator
    = AlreadyAttempted (Random.Generator TestCase)
    | NewCase (Random.Generator TestCase)


getGenerator : Generator -> Random.Generator TestCase
getGenerator generator =
    case generator of
        AlreadyAttempted x ->
            x

        NewCase x ->
            x


isNewCaseGenerator : Generator -> Bool
isNewCaseGenerator generator =
    case generator of
        NewCase _ ->
            True

        AlreadyAttempted _ ->
            False


replaceInternalGenerator : Random.Generator TestCase -> Generator -> Generator
replaceInternalGenerator newInternalGenerator oldGenerator =
    case oldGenerator of
        NewCase _ ->
            NewCase newInternalGenerator

        AlreadyAttempted _ ->
            AlreadyAttempted newInternalGenerator


buildConstantGenerator : User -> TestCase -> Generator
buildConstantGenerator user testCase =
    if User.pllTestCaseIsNewForUser (toTriple testCase) user then
        NewCase (Random.constant testCase)

    else
        AlreadyAttempted (Random.constant testCase)


shouldGenerateNewCase : User -> Maybe TestCase
shouldGenerateNewCase user =
    let
        allTestCases =
            List.Nonempty.Extra.lift3 build
                AUF.all
                PLL.all
                AUF.all
    in
    allTestCases
        |> List.Nonempty.Extra.find (\testCase -> User.pllTestCaseIsNewForUser (toTriple testCase) user)


generate : { now : Time.Posix, overrideWithConstantValue : Maybe TestCase } -> User -> Generator
generate { now, overrideWithConstantValue } user =
    case overrideWithConstantValue of
        Just testCaseOverride ->
            buildConstantGenerator user testCaseOverride

        Nothing ->
            case shouldGenerateNewCase user of
                Just newCase ->
                    buildConstantGenerator user newCase

                Nothing ->
                    let
                        { pllGenerator, generatorType } =
                            generatePLL { now = now } user

                        testCaseGenerator =
                            Random.map TestCase <|
                                Random.map3 (\a b c -> ( a, b, c ))
                                    (List.Nonempty.sample AUF.all)
                                    pllGenerator
                                    (List.Nonempty.sample AUF.all)
                    in
                    replaceInternalGenerator testCaseGenerator generatorType


generatePLL :
    { now : Time.Posix }
    -> User
    -> { pllGenerator : Random.Generator PLL, generatorType : Generator }
generatePLL { now } user =
    let
        statistics =
            User.pllStatistics user

        notAttemptedYets =
            List.filterMap
                (\stat ->
                    case stat of
                        User.CaseNotAttemptedYet pll_ ->
                            Just pll_

                        _ ->
                            Nothing
                )
                statistics

        notYetLearneds =
            List.filterMap
                (\stat ->
                    case stat of
                        User.HasRecentDNF pll_ ->
                            Just pll_

                        _ ->
                            Nothing
                )
                statistics

        fullyLearneds =
            List.filterMap
                (\stat ->
                    case stat of
                        User.AllRecentAttemptsSucceeded record ->
                            Just
                                ( toFloat
                                    (Time.posixToMillis now - Time.posixToMillis record.lastTimeTested)
                                    * record.lastThreeAverageTPS
                                , record.pll
                                )

                        _ ->
                            Nothing
                )
                statistics
    in
    case ( notAttemptedYets, notYetLearneds, fullyLearneds ) of
        ( head :: tail, _, _ ) ->
            { pllGenerator = Random.uniform head tail, generatorType = NewCase (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        ( _, head :: tail, _ ) ->
            { pllGenerator = Random.uniform head tail, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        ( _, _, head :: tail ) ->
            { pllGenerator = Random.weighted head tail, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        -- This should never occur as there should always be at least one list with elements in it
        _ ->
            { pllGenerator = Random.constant PLL.Aa, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }
