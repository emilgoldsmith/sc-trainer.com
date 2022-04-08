module PLLTrainer.TestCase exposing (TestCase, build, generate, pll, postAUF, preAUF, toAlg, toCube)

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
                { toMatchTo = AUF.addToAlgorithm ( preAUF_, postAUF_ ) pllAlgorithm
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
        |> AUF.addToAlgorithm ( preAUF_, postAUF_ )


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


generate : Time.Posix -> User -> Random.Generator TestCase
generate now user =
    Random.map TestCase <|
        Random.map3 (\a b c -> ( a, b, c ))
            (List.Nonempty.sample AUF.all)
            (generatePLL now user)
            (List.Nonempty.sample AUF.all)


generatePLL : Time.Posix -> User -> Random.Generator PLL
generatePLL now user =
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
            Random.uniform head tail

        ( _, head :: tail, _ ) ->
            Random.uniform head tail

        ( _, _, head :: tail ) ->
            Random.weighted head tail

        -- This should never occur as there should always be at least one list with elements in it
        _ ->
            Random.constant PLL.Aa
