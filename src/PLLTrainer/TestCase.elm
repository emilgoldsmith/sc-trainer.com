module PLLTrainer.TestCase exposing (Generator, TestCase, build, generate, getGenerator, isNewCaseGenerator, pll, postAUF, preAUF, toAlg, toCube)

import AUF exposing (AUF)
import AUF.Extra
import Algorithm
import Cube exposing (Cube)
import List.Nonempty
import PLL exposing (PLL)
import Random
import Time
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
                { toMatchTo = Cube.addAUFsToAlgorithm ( preAUF_, postAUF_ ) pllAlgorithm
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
        |> Cube.addAUFsToAlgorithm ( preAUF_, postAUF_ )


{-| A cube that would be solved by this test case
-}
toCube : User -> TestCase -> Cube
toCube user testCase =
    Cube.solved
        |> Cube.applyAlgorithm (Algorithm.inverse <| toAlg user testCase)


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


generate : { now : Time.Posix, overrideWithConstantValue : Maybe TestCase } -> User -> Generator
generate { now, overrideWithConstantValue } user =
    let
        { pllGenerator, generatorType } =
            generatePLL { now = now, overrideWithConstantValue = overrideWithConstantValue } user

        testCaseGenerator =
            case overrideWithConstantValue of
                Just testCaseOverride ->
                    Random.constant testCaseOverride

                Nothing ->
                    Random.map TestCase <|
                        Random.map3 (\a b c -> ( a, b, c ))
                            (List.Nonempty.sample AUF.all)
                            pllGenerator
                            (List.Nonempty.sample AUF.all)
    in
    replaceInternalGenerator testCaseGenerator generatorType


generatePLL :
    { now : Time.Posix, overrideWithConstantValue : Maybe TestCase }
    -> User
    -> { pllGenerator : Random.Generator PLL, generatorType : Generator }
generatePLL { now, overrideWithConstantValue } user =
    case overrideWithConstantValue of
        Just testCaseOverride ->
            let
                testCaseGenerator =
                    Random.constant testCaseOverride

                pllGenerator =
                    testCaseGenerator |> Random.map pll

                statisticsMatchingOverride =
                    user
                        |> User.pllStatistics
                        |> List.filter
                            (\stat ->
                                let
                                    pll_ =
                                        case stat of
                                            User.CaseNotAttemptedYet x ->
                                                x

                                            User.HasRecentDNF x ->
                                                x

                                            User.AllRecentAttemptsSucceeded record ->
                                                record.pll
                                in
                                pll_ == pll testCaseOverride
                            )
            in
            case statisticsMatchingOverride of
                [ overrideStatistic ] ->
                    case overrideStatistic of
                        User.CaseNotAttemptedYet _ ->
                            { pllGenerator = pllGenerator, generatorType = NewCase testCaseGenerator }

                        User.HasRecentDNF _ ->
                            { pllGenerator = pllGenerator, generatorType = AlreadyAttempted testCaseGenerator }

                        User.AllRecentAttemptsSucceeded _ ->
                            { pllGenerator = pllGenerator, generatorType = AlreadyAttempted testCaseGenerator }

                -- This should never happen, there should always be exactly one match for a given pll
                _ ->
                    { pllGenerator = pllGenerator, generatorType = NewCase testCaseGenerator }

        Nothing ->
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
