module Fuzz.Extra exposing (algorithm, algorithmWithoutTPSIgnoredMoves, auf, pll, posix, result, turnDirection, turnFuzzer, turnLength, turnable, user)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Fuzz
import List.Nonempty
import PLL exposing (PLL)
import Time
import User exposing (User)


user : Fuzz.Fuzzer User
user =
    let
        changePLLOperations =
            Fuzz.list (Fuzz.tuple ( pll, algorithm ))
                |> Fuzz.map
                    (List.map
                        (\( pll_, algorithm_ ) ->
                            User.changePLLAlgorithm pll_ algorithm_
                        )
                    )

        recordResultOperations =
            Fuzz.list (Fuzz.tuple ( pll, result ))
                |> Fuzz.map
                    (List.map
                        (\( pll_, result_ ) ->
                            User.recordPLLTestResult pll_ result_
                        )
                    )
    in
    Fuzz.map2
        (\changePLL recordResult ->
            List.foldl
                (\operation user_ -> operation user_)
                User.new
                changePLL
                |> (\initialUser ->
                        List.foldl
                            (\operation user_ -> operation user_ |> Result.withDefault user_)
                            initialUser
                            recordResult
                   )
        )
        changePLLOperations
        recordResultOperations


posix : Fuzz.Fuzzer Time.Posix
posix =
    Fuzz.int |> Fuzz.map Time.millisToPosix


algorithm : Fuzz.Fuzzer Algorithm
algorithm =
    let
        nonEmptyTurnList =
            Fuzz.map2 (::) turnFuzzer <| Fuzz.list turnFuzzer

        nonEmptyTurnListWithNoRepeats =
            nonEmptyTurnList
                |> Fuzz.map
                    (List.foldl
                        (\((Algorithm.Turn nextTurnable _ _) as nextTurn) turns ->
                            case turns of
                                [] ->
                                    [ nextTurn ]

                                (Algorithm.Turn previousTurnable _ _) :: _ ->
                                    if previousTurnable == nextTurnable then
                                        turns

                                    else
                                        nextTurn :: turns
                        )
                        []
                    )
    in
    Fuzz.map Algorithm.fromTurnList nonEmptyTurnListWithNoRepeats


algorithmWithoutTPSIgnoredMoves : Fuzz.Fuzzer Algorithm
algorithmWithoutTPSIgnoredMoves =
    let
        turnablesWithoutYRotations =
            List.Nonempty.filter ((/=) Algorithm.Y)
                (List.Nonempty.head Algorithm.allTurnables)
                Algorithm.allTurnables

        customTurnFuzzer =
            Fuzz.map3
                Algorithm.Turn
                (nonEmptyListToFuzzer turnablesWithoutYRotations)
                turnLength
                turnDirection

        nonEmptyTurnList =
            Fuzz.map2 (::) customTurnFuzzer <| Fuzz.list customTurnFuzzer

        nonEmptyTurnListWithNoRepeats =
            nonEmptyTurnList
                |> Fuzz.map
                    (List.foldl
                        (\((Algorithm.Turn nextTurnable _ _) as nextTurn) turns ->
                            case turns of
                                [] ->
                                    [ nextTurn ]

                                (Algorithm.Turn previousTurnable _ _) :: _ ->
                                    if previousTurnable == nextTurnable then
                                        turns

                                    else
                                        nextTurn :: turns
                        )
                        []
                    )
    in
    Fuzz.map Algorithm.fromTurnList nonEmptyTurnListWithNoRepeats


result : Fuzz.Fuzzer User.TestResult
result =
    Fuzz.map5
        (\correct resultInMilliseconds timestamp preAUF postAUF ->
            if correct then
                User.Correct
                    { timestamp = timestamp
                    , preAUF = preAUF
                    , postAUF = postAUF
                    , resultInMilliseconds = resultInMilliseconds
                    }

            else
                User.Wrong
                    { timestamp = timestamp
                    , preAUF = preAUF
                    , postAUF = postAUF
                    }
        )
        Fuzz.bool
        (Fuzz.intRange 0 15000)
        posix
        auf
        auf


turnFuzzer : Fuzz.Fuzzer Algorithm.Turn
turnFuzzer =
    Fuzz.map3
        Algorithm.Turn
        turnable
        turnLength
        turnDirection


turnDirection : Fuzz.Fuzzer Algorithm.TurnDirection
turnDirection =
    nonEmptyListToFuzzer Algorithm.allTurnDirections


turnLength : Fuzz.Fuzzer Algorithm.TurnLength
turnLength =
    nonEmptyListToFuzzer Algorithm.allTurnLengths


turnable : Fuzz.Fuzzer Algorithm.Turnable
turnable =
    nonEmptyListToFuzzer Algorithm.allTurnables


pll : Fuzz.Fuzzer PLL
pll =
    nonEmptyListToFuzzer PLL.all


auf : Fuzz.Fuzzer AUF
auf =
    nonEmptyListToFuzzer AUF.all


nonEmptyListToFuzzer : List.Nonempty.Nonempty a -> Fuzz.Fuzzer a
nonEmptyListToFuzzer =
    List.Nonempty.toList >> listToFuzzer


listToFuzzer : List a -> Fuzz.Fuzzer a
listToFuzzer list =
    Fuzz.oneOf <| List.map Fuzz.constant list
