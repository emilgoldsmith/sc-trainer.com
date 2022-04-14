module Fuzz.Extra exposing (algorithm, algorithmWithoutTPSIgnoredTurns, auf, pll, posix, testResult, turnDirection, turnFuzzer, turnLength, turnable, user)

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
            Fuzz.list <| Fuzz.map2 User.changePLLAlgorithm pll algorithm

        recordResultOperations =
            Fuzz.list <| Fuzz.map2 User.recordPLLTestResult pll testResult
    in
    Fuzz.constant User.new
        |> Fuzz.map2
            (\changePLLOperations_ curUser ->
                List.foldl
                    (\operation user_ -> operation user_)
                    curUser
                    changePLLOperations_
            )
            changePLLOperations
        |> Fuzz.map2
            (\recordResultOperations_ curUser ->
                List.foldl
                    (\operation user_ -> operation user_ |> Result.withDefault user_)
                    curUser
                    recordResultOperations_
            )
            recordResultOperations
        |> Fuzz.map3
            (\recognitionTime tps ->
                User.changePLLTargetParameters { targetRecognitionTimeInSeconds = recognitionTime, targetTps = tps }
            )
            (Fuzz.floatRange 0.1 100)
            (Fuzz.floatRange 0.1 30)


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


algorithmWithoutTPSIgnoredTurns : Fuzz.Fuzzer Algorithm
algorithmWithoutTPSIgnoredTurns =
    Fuzz.map2
        (\originalAlgorithm backupAlgorithm ->
            originalAlgorithm
                |> Algorithm.toTurnList
                |> List.filter (not << isYRotation)
                |> Algorithm.fromTurnList
                |> (\filtered ->
                        if filtered == Algorithm.empty then
                            backupAlgorithm

                        else
                            filtered
                   )
        )
        algorithm
        (Algorithm.allTurns
            |> List.Nonempty.filter (not << isYRotation) (Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise)
            |> nonEmptyListToFuzzer
            |> Fuzz.map (List.singleton >> Algorithm.fromTurnList)
        )


isYRotation : Algorithm.Turn -> Bool
isYRotation (Algorithm.Turn turnable_ _ _) =
    turnable_ == Algorithm.Y


testResult : Fuzz.Fuzzer User.TestResult
testResult =
    Fuzz.map5
        (\correct resultInMilliseconds timestamp auf1 auf2 ->
            if correct then
                User.Correct
                    { timestamp = timestamp
                    , preAUF = auf1
                    , postAUF = auf2
                    , resultInMilliseconds = resultInMilliseconds
                    }

            else
                User.Wrong
                    { timestamp = timestamp
                    , preAUF = auf1
                    , postAUF = auf2
                    }
        )
        Fuzz.bool
        (Fuzz.intRange 1 15000)
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
