module Fuzz.Extra exposing (algorithm, algorithmWithoutTPSIgnoredTurns, auf, pll, posix, testResult, turnDirection, turnFuzzer, turnLength, turnable, user)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Array
import Dict exposing (Dict)
import Fuzz
import List.Nonempty
import PLL exposing (PLL)
import Time
import User exposing (User)


user : Fuzz.Fuzzer User
user =
    let
        changePLLOperationsFuzzer =
            Fuzz.list <|
                (pll
                    |> Fuzz.andThen
                        (\pll_ ->
                            Dict.get (PLL.getLetters pll_) pllAlgorithms
                                |> Maybe.withDefault [ Algorithm.empty ]
                                |> Fuzz.oneOfValues
                                |> Fuzz.map (User.changePLLAlgorithm pll_)
                        )
                )

        recordResultOperationsFuzzer =
            Fuzz.list <| Fuzz.map2 User.recordPLLTestResult pll testResult
    in
    Fuzz.constant User.new
        |> Fuzz.map2
            (\changePLLOperations curUser ->
                List.foldl
                    (\operation user_ -> operation user_)
                    curUser
                    changePLLOperations
            )
            changePLLOperationsFuzzer
        |> Fuzz.map2
            (\recordResultOperations curUser ->
                List.foldl
                    (\operation user_ -> operation user_ |> Result.withDefault user_)
                    curUser
                    recordResultOperations
            )
            recordResultOperationsFuzzer
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


{-| Generated using the following Cypress code, followed by some semi-manual filtering on straight up
wrong algorithms that were in AlgDB:

it.only("temp", function () {
allPLLs.forEach((pll) => {
const pllString = pllToPllLetters[pll];
cy.visit("<http://algdb.net/puzzle/333/pll/"> + pllString.toLowerCase());
cy.get("td:nth-child(1)").then((nodes) => {
let text = `("${pllString}", [`;
nodes.each((\_, node) => {
text += `"${node.innerText}",`;
});
text +=
"] |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)), ";
cy.log(text);
});
});
});

-}
pllAlgorithms : Dict String (List Algorithm)
pllAlgorithms =
    Dict.fromList
        [ ( "Aa"
          , [ "l' U R' D2 R U' R' D2 R2"
            , "x R' U R' D2 R U' R' D2 R2"
            , "R' F R' B2 R F' R' B2 R2"
            , "y x' R2 D2 R' U' R D2 R' U R' x"
            , "y' x L2 D2 L' U' L D2 L' U L'"
            , "x' R' D R' U2 R D' R' U2 R2"
            , "y' r U r' U' r' F r2 U' r' U' r U r' F'"
            , "y' R U R' F' r U R' U' r' F R2 U' R'"
            , "y2 x' L' U L' D2 L U' L' D2 L2"
            , "R' D' R U2 R' D R U' R' D' R U' R' D R"
            , "y2 L' B L' F2 L B' L' F2 L2"
            , "U' r U r' U' r' F r2 U' r' U' r U r' F'"
            , "y2 r' U L' D2 L U' L' D2 L2"
            , "y' r U r' U' r' F r2 U' r' U' r U r' F'"
            , "R' F R' f2 r U' r' f2 R2"
            , "x' R' U' R U R' D' R U' R' U D R x"
            , "L' U R' D2 R U' R' D2 R L"
            , "y x R2 U2 R' D' R U2 R' D R'"
            , "y2 r' U r' B2 r U' r' B2 r2"
            , "l' U R' u2 L U' L' u2 l R"
            , "y2 R' D' R U' R' D R U' R' D' R U2 R' D R"
            , "y' r U R' F' r U R' U' r' F R2 U' r'"
            , "y R' D' R U' R' D R U2 R' D' R U' R' D R"
            , "U' r U r' U' r' F r2 U' r' U' r U r' F' U2"
            , "x' R' U' R U R' D' R U' R' D U R x"
            , "l' U R' z r2 U R' U' r2 u2"
            , "y' r2 U r2 U' r2 U' D r2 U' r2 U r2 D'"
            , "y R' D' R U' R' D R U2 R' D' R U' R' D R"
            , "R' F l' D2 R U' R' D2 R2"
            , "R2 U D R2 U' R2 U R2 D' R2 U' R2 U R2 U' R2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ab"
          , [ "x R2 D2 R U R' D2 R U' R x'"
            , "l' R' D2 R U R' D2 R U' R x'"
            , "y x' R U' R D2 R' U R D2 R2 x"
            , "y' x L U' L D2 L' U L D2 L2"
            , "y l U' R D2 R' U R D2 R2"
            , "R2 B2 R F R' B2 R F' R"
            , "y' r U' L D2 L' U L D2 L2"
            , "x' R2 U2 R D R' U2 R D' R"
            , "y R B' R F2 R' B R F2 R2"
            , "R' D' R U R' D R U R' D' R U2 R' D R"
            , "l' U' l U l F' l2 U l U l' U' l F"
            , "y2 r' L' D2 L U L' D2 L U' L"
            , "y x R D' R U2 R' D R U2 R2"
            , "y' x' L D' L U2 L' D L U2 L2"
            , "y2 R' D' R U2 R' D R U R' D' R U R' D R"
            , "R2 f2 r U r' f2 R F' R"
            , "y' x L U' L D2 L' U L D2 L2"
            , "y' L F' r D2 L' U L D2 r2"
            , "L' U' L F l' U' L U l F' L2 U L"
            , "x' R' D' U' R U R' D R U' R' U R x"
            , "y2 r2 B2 r U r' B2 r U' r"
            , "l' R' D2 R U R' D2 R U' l"
            , "y l U' R z r2 U' R U r2 u2"
            , "R2 D' R2 U R2 U' D R2 U R2 D' R2 D"
            , "y R' D' R U R' D R U2 R' D' R U R' D R"
            , "y' R U R2 U' R' F R U R U' R' F' R U R U' R'"
            , "y' r U' L u2 R' U R u2 r L"
            , "L' U' L F l' U' L U R U' r2 F r"
            , "y x' R U' R z' R2 U' r B R2 B2"
            , "y z U R' D r2 U' R U r2 U' D'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "E"
          , [ "y x' R U' R' D R U R' D' R U R' D R U' R' D' x"
            , "R2 U R' U' y R U R' U' R U R' U' R U R' y' R U' R2"
            , "z U2 R2 F R U R' U' R U R' U' R U R' U' F' R2 U2 z'"
            , "R2 U R2 U D R2 U' R2 U R2 U' D' R2 U R2 U2 R2"
            , "y x' R U' R' D R U R' u2 R' U R D R' U' R x"
            , "y R' U' R' D' R U' R' D R U R' D' R U R' D R2"
            , "F' r U R' U' r' F R U2 r U R' U' r' F R F'"
            , "F R' F' r U R U' r' F R F' r U R' U' r'"
            , "L U' R D2 R' U R L' U' L D2 L' U R'"
            , "y R U R' U R' U' R F' R U R' U' R' F R2 U' R2 U R"
            , "y R2 D' R U' R' D R U' R' D' R U R' D R U R"
            , "R' U L' D2 L U' R L' U R' D2 R U' L"
            , "R U' L D2 L' U R' L U' R D2 R' U L'"
            , "x U R' U' L U R U' L' U R U' L U R' U' r'"
            , "x U R' U' L U R U' r2 U' R U L U' R' U"
            , "l' U' L' U R U' L U R' U' L U R U' L' U"
            , "R2 D R' U2 R D' R' U' R D R' U R D' R' U2 R'"
            , "y R U R D R' U R D' R' U' R D R' U' R D' R2"
            , "L U' R D2 R' U L' R U' L D2 L' U R'"
            , "y x R' U R D' R' U' R D R' U' R D' R' U R D x'"
            , "z U2 R2 F U R U' R' U R U' R' U R U' R' F' R2 U2 z'"
            , "y' R' U' R' D' R U' R' D R U R' D' R U R' D R2"
            , "y l U' R' D R U R' D' R U R' D R U' R' D' x"
            , "L' U R' D2 R U' L R' U L' D2 L U' R"
            , "L R' U' R U L' U' R' U R r U R' U' r' F R F'"
            , "R2 U R' y R U' R' U R U' R' U R U' R' U F U' F2"
            , "y x R' U R' D2 R U' R' D2 R2 z' R' U R' D2 R U' R' D2 R2"
            , "l' U' r' F R F' R U R' U' L U R U' R' F"
            , "y x R D' R' U R D R' U' R D R' U R D' R' U' x'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "F"
          , [ "y R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R"
            , "y2 R' U2 R' d' R' F' R2 U' R' U R' F R U' F"
            , "R' U R U' R2 F' U' F U R F R' F' R2"
            , "M' U2 L F' R U2 r' U r' R2 U2 R2"
            , "R' U R U' R2 y' R' U' R U y x R U R' U' R2 x'"
            , "y2 R' U2 R' U' y R' F' R2 U' R' U R' F R U' F"
            , "y' L U F L' U' L U L F' L2 U L U L' U' L U' L'"
            , "y R2 F R F' R' U' F' U F R2 U R' U' R"
            , "R U R' U' R' U R U2 L' R' U R U' L U' R U' R'"
            , "M U x' R2 U2 R2 r U' r U2 l' U r'"
            , "M' U2 r U' R x' U2 r' U R2 r' U2 R' l'"
            , "R U R' U L' U L U2 R' L' U L U' R U R U' R'"
            , "y' z D' U2 R' U' R' U2 R U R U2 R U' R2 D R' U"
            , "r U R' U' z U' l' U2 r' U' r U2 l' U l' R'"
            , "y2 R' U2 R' U' R D' R' D R' U D' R2 U' R2 D R U' R"
            , "y R2 U R2 U D R2 U2 D' R2 U2 R2 U R2 D R2 U' D' R2"
            , "y' x D' l2 D' l' z' R' F' R2 U' R' U R' F R U' f"
            , "y x U R2 F R2 U' R' U R' x U2 r U' r' U l R U' x'"
            , "y' F r2 R' U2 r U' r' U2 l R U' R' U r2 u'"
            , "y2 R' U2 R' U' x2 y' R' U R' U' l2 F' R' F R U' F"
            , "y R U2 R' U' r U2 R' F R U2 r2 F R2 U2 r' M2"
            , "y2 R U' R' U R2 y R U R' U' x U' R' U R U2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ga"
          , [ "R2 u R' U R' U' R u' R2 y' R' U R"
            , "R2 U R' U R' U' R U' R2 D U' R' U R D'"
            , "R2 u R' U R' U' R u' R2 F' U F"
            , "D' R2 U R' U R' U' R U' R2 U' D R' U R"
            , "y R U R' F' R U R' U' R' F R U' R' F R2 U' R' U' R U R' F'"
            , "R2 u R' U R' U' R u' R2 y L' U L"
            , "L2 F2 L' U2 L' U2 L F' L' U' L U L F' L2"
            , "R U R' U' R' U F R U R U' R' F' U R' U2 R"
            , "F2 R2 L2 U R2 U' R2 D R2 D' L2 F2"
            , "y2 R U' R U R2 D R' U' R D' R' U2 R U' R' U' R2"
            , "y2 L2 u L' U L' U' L u' L2 y' L' U L"
            , "r U2 R U' r' F U R' U' F' r U' r'"
            , "R2 S2 U l2 U' l2 u R2 U' r2 F2"
            , "y' R U2 R' U' F' R U R2 U' R' F R U R2 U2 R'"
            , "y2 z U2 r U' R U' R' U r' U2 x' U' R U x z'"
            , "y2 R l U2 l' U2 R' U2 l U' R' F' R F R U' R2"
            , "R2 u R' U R' U' R u' R2 b' R b"
            , "y' u' L2 U L' U L' U' L U' L2 U' D L' U L"
            , "R2 u R' U R' U' R u' R2 b' R F"
            , "y' R L U2 R' L' F' U B' U2 F U' B"
            , "y2 x' R2 U2 R' F2 R' F2 R U' R' F' R F R U' R2"
            , "L U' R' U x U2 r' R U R' U' r U2 r' U' R"
            , "y2 L2 U L' U L' U' L U' L2 U' D L' U L D'"
            , "R2 u R' U R' U' R u' R2 z x U' R U"
            , "R2 U' R2 U R2 U' D' R2 U2 R2 U' R2 U R2 U2 R2 U' D"
            , "l U2 R' r U r' F' D R U' R' D' R U' l'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Gb"
          , [ "R' U' R U D' R2 U R' U R U' R U' R2 D"
            , "R' U' R y R2 u R' U R U' R u' R2"
            , "y F' U' F R2 u R' U R U' R u' R2"
            , "R' d' F R2 u R' U R U' R u' R2"
            , "D R' U' R U D' R2 U R' U R U' R U' R2"
            , "y R U R' F' r U R' U' r' F R F' R U R' U' R' F R2 U' R'"
            , "y2 L' U' L y' R2 u R' U R U' R u' R2"
            , "y2 R' U2 R U' F R U R' U' R' F' U' R U R U' R'"
            , "y2 L' U' L y L2 u L' U L U' L u' L2"
            , "y r U r' F U R U' F' r U R' U2 r'"
            , "R' U' y F R2 u R' U R U' R u' R2"
            , "R' U' R U D' R2 U R' U R U' R U' R2 u"
            , "y2 L' U' L U D' L2 U L' U L U' L U' L2 D"
            , "y' l U R' D R U R' D' F r U' r' R U2 l'"
            , "y2 L' U' L U D' L2 U L' U L U' L U' L2 D"
            , "R' U' R B2 D L' U L U' L D' B2 U2"
            , "y' R' U L' U2 R U' L y' L R U2 L' R'"
            , "y' u R' U' R U D' R2 U R' U R U' R U' R2"
            , "y u L' U' L U D' L2 U L' U L U' L U' L2"
            , "y u' L' U' L U D' L2 U L' U L U' L U' L2 D2"
            , "L' U R' U2 L U' R y' L R U2 L' R'"
            , "R' U r U2 r' U R U' R' r U2 x' U' R U L'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Gc"
          , [ "R2 u' R U' R U R' u R2 y R U' R'"
            , "y2 R2 F2 R U2 R U2 R' F R U R' U' R' F R2"
            , "R2 U' R U' R U R' U R2 D' U R U' R' D"
            , "R2 u' R U' R U R' u R2 f R' f'"
            , "y2 L2 u' L U' L U L' u L2 y L U' L'"
            , "D R2 U' R U' R U R' U R2 U D' R U' R'"
            , "R2 u' R U' R U R' u R2 B U' B'"
            , "R2 u' R U' R U R' D x' U2 r U' r'"
            , "y2 L2 U' L U' L U L' U L2 D' U L U' L' D"
            , "y2 L2 u' L U' L U L' u L2 y' R U' R'"
            , "y2 R2 F2 R U2 R r' F r U2 R' U' F2 R"
            , "y F2 D' L U' L U L' D F2 R U' R'"
            , "R2 F2 R U2 M F r U2 R' U' F2 R"
            , "R2 S2 U' l2 U l2 u' R2 U r2 B2"
            , "R2 U' R U' R U R' U R2 D' U R U' R' u"
            , "D R2 U' R U' R U R' U R2 D' U R U' R'"
            , "R2 u' R U' R U R' u R2 f R' f'"
            , "y2 L2 u' L U' L U L' u L2 F U' F'"
            , "U' L' R' U2 L R F U' B U2 F' U B'"
            , "U' B2 D' R U' R U R' D B2 L U' L'"
            , "y L' U' L F L' U' L U L F' L' U L F' L2 U L U L' U' L F"
            , "y' R' L' U2 R L y' R U' L U2 R' U L' U2"
            , "y' L' R' U2 L R y L U' R U2 L' U R'"
            , "y' u R2 U' R U' R U R' U R2 D' U R U' R'"
            , "y u L2 U' L U' L U L' U L2 D' U L U' L'"
            , "y F2 R2 L2 U' L2 U L2 D' L2 D R2 F2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Gd"
          , [ "R U R' U' D R2 U' R U' R' U R' U R2 D'"
            , "R U R' y' R2 u' R U' R' U R' u R2"
            , "D' R U R' U' D R2 U' R U' R' U R' U R2"
            , "f R f' R2 u' R U' R' U R' u R2"
            , "R U R' F' R U R' U R U' R' U' R' F R2 U R' U' R U' R'"
            , "y R2 F' R U R U' R' F' R U2 R' U2 R' F2 R2"
            , "y2 L U L' B2 D' R U' R' U R' u R2"
            , "y2 L U L' U' D L2 U' L U' L' U L' U L2 D'"
            , "y2 L U L' y' L2 u' L U' L' U L' u L2"
            , "y F U F' L2 u' L U' L' U L' u L2"
            , "y2 L U r' U2 x D' R U' R' U R' u R2"
            , "F2 R2 D' L2 D L2 U' L2 U M2 B2"
            , "R U R' y L2 u' L U' L' U L' u L2"
            , "y2 x' r U r' U2 x D' R U' R' U R' u R2"
            , "y R U' L U2 R' U L' y' L' R' U2 L R"
            , "R U R' D U' R2 U' R U' R' U R' U R2 u'"
            , "y u' R U R' U' D R2 U' R U' R' U R' U R2"
            , "R U R' y' R2 u' R U' R' U R' D B2"
            , "y' u' L U L' U' D L2 U' L U' L' U L' U L2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "H"
          , [ "M2 U M2 U2 M2 U M2"
            , "M2 U' M2 U2 M2 U' M2"
            , "R2 U2 R U2 R2 U2 R2 U2 R U2 R2"
            , "M2 U' M2 U2 M2 U' M2"
            , "R2 U2 R2 U2 R2 U' R2 U2 R2 U2 R2"
            , "M2 U2 M2 U' M2 U2 M2"
            , "R2 U2 R' U2 R2 U2 R2 U2 R' U2 R2"
            , "M2 u' M2 u2 M2 u' M2"
            , "M2 u M2 u2 M2 u M2"
            , "M2 U M2 U M2 U M2 U M2 U M2"
            , "R L U2 L' R' y L' R' U2 R L"
            , "M2 U2 M2 U M2 U2 M2"
            , "S R U2 R2 U2 R2 U2 R S'"
            , "x' R r U2 r' R' U' u' R2 U D"
            , "R U R' U2 R U' R' U' R U' R' U2 R U' R' U' R U2 R'"
            , "M' U M2 U2 M2 U M2 U2 M'"
            , "R U F' R U R' U R2 U2 R' F U' R' U R' U2 R"
            , "F B' U' R2 U2 R2 U2 R2 U' F' B"
            , "M' U' M2 U2 M2 U' M2 U2 M'"
            , "r' R y' R U2 R2 U2 R2 U2 R S'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ja"
          , [ "y R' U L' U2 R U' R' U2 R L"
            , "L' U' L F L' U' L U L F' L2 U L"
            , "y2 x R2 F R F' R U2 r' U r U2 x'"
            , "y2 R' U2 R U R' U2 L U' R U L'"
            , "L' U2 L U L' U2 R U' L U R'"
            , "y2 F U' R' F R2 U' R' U' R U R' F' R U R' F'"
            , "x U2 r' U' r U2 l' U R' U' R2"
            , "L' U R' z R2 U R' U' R2 U D"
            , "y' z U' R D' R2 U R' U' R2 U D R' z'"
            , "L U' R' U L' U2 R U' R' U2 R"
            , "y2 R' U2 R U R' z R2 U R' D R U'"
            , "R U' L' U R' U2 L U' L' U2 L"
            , "y2 L U' R' U L' U2 R U' R' U2 R"
            , "F U' R' F R2 U' R' U' R U R' F' R U R' F'"
            , "y2 F2 L' U' r U2 l' U R' U' R2"
            , "R2 F2 U' F2 D R2 D' R2 U R2"
            , "y R' U' R' D R2 U' R' U R2 D' R2 U R"
            , "y2 R' F R F' r U R' U' r' U2 R U R' U R"
            , "R2 U' D R2 U' R2 U R2 D' R2 U R2"
            , "L' R' U2 R U R' U2 L U' R"
            , "y x' R2 u' R' u R2 x' y' R' U R' U' R2"
            , "r2 U D' r2 U' r2 D r2 D' r2 D r2"
            , "l' R' F R F' R U2 r' U r U2 x'"
            , "R2 U' R2 D R2 U' R2 U R2 U D' R2"
            , "y2 R' U2 R U R' U2 L U' R U L'"
            , "R' U2 z D R D' R2 U R' D R U'"
            , "y2 R2 U' R2 D R2 U' R2 U R2 U D' R2"
            , "y2 l D l' U l D' l' U2 l D l' U l D' l'"
            , "y2 R2 U' R' U R' U' R' F R2 U' R' U' R U R' F' R2 U R2"
            , "z D' R2 D R D' R2 U R' D R U'"
            , "y2 R' U' R B R' U' R U R B' R2 U R U"
            , "y2 r U' r' U' r U r D r' U' r D' r' U2 R' U' M"
            , "r U r' U2 r' D' r U' r' D r U' r U' r'"
            , "U2 L U' R' U L' U2 R U' R' U2 R U2"
            , "y F2 L' U' r U2 l' U R' U' l2"
            , "y2 F2 D' L2 D L2 U' L2 U L2 F2 U"
            , "D' R2 U2 R2 D R2 U2 D' R2 U R2 U R2 U' R2 D R2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Jb"
          , [ "R U R' F' R U R' U' R' F R2 U' R'"
            , "R U2 R' U' R U2 L' U R' U' L"
            , "R U2 R' U' R U2 L' U R' U' r x"
            , "L' U R U' L U2 R' U R U2 R'"
            , "y' L U' R U2 L' U L U2 R' L'"
            , "y R U' L U2 R' U R U2 L' R'"
            , "y R2 U D' R2 U R2 U' R2 D R2 U' R2"
            , "R L U2 R' U' R U2 L' U R'"
            , "R2 U R2 U R2 U' R2 D R2 D' R2 U' R2 D R2 D'"
            , "r' F R F' r U2 R' U R U2 R'"
            , "B2 L U L' B2 R D' R D R2"
            , "y2 R L U2 L' U' L U2 R' U L' U"
            , "y2 R' U2 R U R' F' R U R' U' R' F R2 U' R' U R"
            , "y' L r U2 R2 F R F' R U2 r' U L'"
            , "y2 r' D' r U' r' D r U2 r' D' r U' r' D r"
            , "y2 R' U L U' R U2 L' U L U2 L'"
            , "R U l' U' l U R' U' l' U l R U' R' U'"
            , "y2 R L U2 L' U' L U2 R' U L'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Na"
          , [ "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'"
            , "L U' R U2 L' U R' L U' R U2 L' U R'"
            , "z U R' D R2 U' R D' U R' D R2 U' R D' z'"
            , "r' D r U2 r' D r U2 r' D r U2 r' D r U2 r' D r"
            , "R U' L U2 R' U L' R U' L U2 R' U L'"
            , "F' R U R' U' R' F R2 F U' R' U' R U F' R'"
            , "z R' U R' D R2 U' R U D' R' D R2 U' R D' z'"
            , "R U R' U R U2 R' U' R U2 L' U R' U' L U' R U' R'"
            , "z D R' U R2 D' R U' D R' U R2 D' R U' z'"
            , "L U' L' U L F U F' L' U' L F' L F L' U L'"
            , "R U2 D' R U2 R' U' D R2 U' D' R U R' D R2"
            , "L U' R U2 r' F M' U' R U2 r' F l'"
            , "L U' R U2 L' U R' L U' R U2 L' U R' U'"
            , "R U' R' U l U F U' R' F' R U' R U R' F R'"
            , "F' R2 U R2 U' R2 F U2 F' R2 U R2 U' R2 F"
            , "R' U R2 B2 U R' B2 R U' B2 R2 U' R U'"
            , "R U2 R U2 R' U2 D R' U R2 D' R D R2 U' D'"
            , "R U R' U r' F R F' r U2 R' U R U2 R' U' R U' R'"
            , "z2 L D L' D L D L' F' L D L' D' L' F L2 D' L' D2 L D' L'"
            , "R2 D r' U2 r D' R' U2 R' U2 F R U' R' U' R U2 R' U' F'"
            , "x L' U' L B2 L' U' L B2 L' U' L B2 L' U' L B2 L' U' L x'"
            , "R U R' U R L U2 R' U' R U2 L' U R' U2 R U' R'"
            , "l F' R' U' R z' R U' R' U' r U l' U R' U' R2"
            , "L R U' R' U L' U2 R U' R2 D' r U2 r' D R"
            , "R' U R U' R' L' D2 L U2 L' D2 L R U R' U' R"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Nb"
          , [ "R' U R U' R' F' U' F R U R' F R' F' R U' R"
            , "R' U L' U2 R U' L R' U L' U2 R U' L"
            , "z D' R U' R2 D R' U D' R U' R2 D R' U z'"
            , "r D r' U2 r D r' U2 r D r' U2 r D r' U2 r D r'"
            , "L' U' L U' L' U' L F L' U' L U L F' L2 U L U2 L' U L"
            , "r' D' F r U' r' F' D r2 U r' U' r' F r F'"
            , "z U' R D' R2 U R' D U' R D' R2 U R' D z'"
            , "R' U R' F R F' R U' R' F' U F R U R' U' R"
            , "L' U R' U2 L U' R L' U R' U2 L U' R"
            , "l D' l' U2 l D' l' U2 l D' l' U2 l D' l' U2 l D' l'"
            , "R' U L' U2 R U' M' B r' U2 R U' L"
            , "R' U R U' R' F' U' F R U R' U' R U' f R f'"
            , "R' U R U' R' F' U' F R U R' U' R d' R U R'"
            , "L' U' L R' U L' U2 R U' R' U2 L R U' L' U L"
            , "z U' R2 U R U R' F' R U R' U' R' F R2 U' R' U2 R2 U"
            , "R U' R2 F2 U' R F2 R' U F2 R2 U R'"
            , "r D' r' U2 r D' r' U2 r D' r' U2 r D' r' U2 r D' r'"
            , "R' U' R U' R' L' U2 R U R' U2 L U' R U2 R' U R"
            , "L' U R' U2 L U' L' R U R' U2 L U' R"
            , "B R2 U' R2 U R2 B' U2 B R2 U' R2 U R2 B'"
            , "r' D' F r U' r' F' D r2 U r' U' L' U r U'"
            , "R' U2 D R' U2 R U D' R2 U D R' U' R D' R2"
            , "R' U' R U' x R2 F R F' R U2 r' U r U2 x' U R' U R"
            , "L U' L2 B2 U' L B2 L' U B2 L2 U L' U"
            , "L' U' L U R' U2 R U R' U2 z U R' D R U' R' U' R U z'"
            , "L' R' U R U' L U2 R' U R2 D r' U2 r D' R'"
            , "z U' R' U D' R U' R2 D R' D' R2 U D R' U' R U z'"
            , "L' U' L U L U' R' U L' U2 R U' R' U2 R U' L' U L"
            , "r' U R U' R' U r' F' r U r U2 r' F2 U2 r"
            , "D' U R2 D R D' R2 U R' D U2 R' U2 R U2 R"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ra"
          , [ "y R U R' F' R U2 R' U2 R' F R U R U2 R'"
            , "L U2 L' U2 L F' L' U' L U L F L2"
            , "y R U' R' U' R U R D R' U' R D' R' U2 R'"
            , "y2 R U2 R' U2 R B' R' U' R U R B R2"
            , "y2 R U2 R' U' R' F' R U2 R U2 R' F R U' R'"
            , "R U R' F' U' F R U R' F R' F' R2 U2 R'"
            , "y' L2 F' L' U' L' U L F L' U2 L U2 L'"
            , "y2 R U' R2 D' R U R' D R U' R U' R' U R U R'"
            , "y2 R U2 R D R' U R D' R' U' R' U R U R'"
            , "R2 F2 U R U R' U' R' U' F2 R' U R' U'"
            , "y R U' R' U' R U R' U R' D' R U' R' D R2 U R'"
            , "y2 R U2 R' U2 l U' l' U' R U l U R2"
            , "y R l U' l' U' R' U l U l' U2 R U2 R'"
            , "R U2 R2 F R F' R U' R' F' U F R U' R'"
            , "y2 R U' R F2 U R U R U' R' U' F2 R2"
            , "y' z U2 R2 U' r' U r U' r' U' r d' R U' R' U' F2 U2"
            , "y' L U' L' U' L U L D L' U' L D' L' U2 L'"
            , "y2 R U2 R' U2 R B' R' U' R U R B R2"
            , "L U2 L D L' U L D' L' U' L' U L U L'"
            , "L U2 L' U F R' F' L F R F' U L'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Rb"
          , [ "R' U2 R U2 R' F R U R' U' R' F' R2"
            , "R' U2 R' D' R U' R' D R U R U' R' U' R"
            , "y R2 F R U R U' R' F' R U2 R' U2 R"
            , "y' R U2 R' U2 R' F R2 U' R' U' R U R' F' R U R' U R U2 R'"
            , "y2 r' F2 r F R U' R' U' F' U' r U' r' F"
            , "y' L' U L U L' U' L' D' L U L' D L U2 L"
            , "y2 R U R' U' f' U2 F2 R U R' U' F2 U2 f"
            , "y R' U R U R' U' R' D' R U R' D R U2 R"
            , "y2 R U R' U2 r' U2 R' f' U' f R2 U2 r"
            , "y2 L' U2 L' D' L U' L' D L U L U' L' U' L"
            , "R' U2 R U' x U' r x' U R' U' L' U x' U' R"
            , "y2 L' U L' F2 U' L' U' L' U L U F2 L2"
            , "y2 x r' U r' D2 r U' r' D2 r2 x' U R' L F2 L' R"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "T"
          , [ "R U R' U' R' F R2 U' R' U' R U R' F'"
            , "R U R' U' R' F R2 U' R' U F' L' U L"
            , "R2 U R2 U' R2 U' D R2 U' R2 U R2 D'"
            , "y2 L' U' L U L F' L2 U L U L' U' L F"
            , "y F2 D R2 U' R2 F2 D' r2 D r2"
            , "R2 u R2 U' R2 F2 D' r2 D r2"
            , "R U R' U' R U' R' U' R U R' F' R U R' U' R' F R U R U' R'"
            , "D' R2 U R2 U' R2 U' D R2 U' R2 U R2"
            , "R U R' U' R2 D R' U' R' U' R U R2 D' R"
            , "y F2 D R2 U' R2 F2 D' L2 U L2 U'"
            , "R2 u' R2 U R2 y R2 u R2 U' R2"
            , "y' R' U R' F2 r F' r' F2 R2 U' M U2 M'"
            , "R U' R' U2 L R U' R' U' R' U2 R U2 L' U' R' U R"
            , "y' M' R' U R' F2 r F' r' F2 R2 U' M"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ua"
          , [ "y2 R U' R U R U R U' R' U' R2"
            , "R2 U' R' U' R U R U R U' R"
            , "y2 M2 U M U2 M' U M2"
            , "M2 U M' U2 M U M2"
            , "R U R' U R' U' R2 U' R' U R' U R"
            , "y R2 U' S' U2 S U' R2"
            , "y2 F2 U' L R' F2 L' R U' F2"
            , "y M2 u' M' u2 M' u' M2"
            , "L U' L U L U L U' L' U' L2"
            , "y R2 U S R2 S' R2 U' R2"
            , "y R2 U' F B' R2 B F' U' R2"
            , "R U R' U' L' U' L U2 R U' R' U' L' U L"
            , "y2 L2 U' L' U' L U L U L U' L"
            , "y R U R' U' R' U2 R U R U' R2 U2 R"
            , "r U r' R U R' U' M' U R U2 r'"
            , "y' M2 u M' u2 M' u2 M' u2 M' u M2"
            , "y R2 D' M' U2 M U2 D R2"
            , "y2 F2 U' M' U2 M U' F2"
            , "y R U2 R U R U R2 U' R' U' R2"
            , "y2 L U L' U L' U' L2 U' L' U L' U L"
            , "y F U R U' R' F' U2 F' L' U' L U F"
            , "y2 M' U2 M U M' U2 M U M' U2 M"
            , "y' R U R2 U' R' U' R U R U R U' R U' R'"
            , "y F U R U' R' F' f' U' L' U L f"
            , "y' R' U' R U' R U R U R U' R' U' R2 U R"
            , "R' U' R U' R' U2 R U' L U L' U L U2 L'"
            , "y R2 U' F B' R2 F' B U' R2"
            , "M U2 M' U M U2 M' U M U2 M'"
            , "y F U R U' R' F' y2 F' L' U' L U F"
            , "y' M2 u' M u2 M u' M2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Ub"
          , [ "y2 R2 U R U R' U' R' U' R' U R'"
            , "y2 M2 U' M U2 M' U' M2"
            , "R' U R' U' R' U' R' U R U R2"
            , "M2 U' M' U2 M U' M2"
            , "y2 L' U L' U' L' U' L' U L U L2"
            , "y' M2 u M' u2 M' u M2"
            , "y2 F2 U L R' F2 L' R U F2"
            , "y R2 U' S R2 S' R2 U R2"
            , "L2 U L U L' U' L' U' L' U L'"
            , "y2 R' U' R U' R U R2 U R U' R U' R'"
            , "y R2 U F B' R2 F' B U R2"
            , "y R2 U R2 S R2 S' U' R2"
            , "L U L' U L U2 L' U R' U' R U' R' U2 R U'"
            , "L' U' L U R U R' U2 L' U L U R U' R'"
            , "y' M2 U' M2 U2 M' U2 M' U M2"
            , "R U R' F' R U R' U' M' U R U' r' F R U' R'"
            , "L' U' L U' L U L2 U L U' L U' L'"
            , "L' U' L U R U R' U2 L' U L U R U' R'"
            , "M U2 M' U' M U2 M' U' M U2 M'"
            , "y M2 U' M2 U2 M' U2 M' U M2"
            , "L' U' L U' L U L2 U L U' L U' L'"
            , "y R' U2 R2 U R' U' R' U2 R U R U' R'"
            , "y' R U R' U R' U' R' U' R' U R U R2 U' R'"
            , "l' U' l L' U' L U M' U' L' U2 l"
            , "y' R' U' R2 U R U R' U' R' U' R' U R' U R"
            , "R U R' U' R' U' R' U R d' M' U2 M"
            , "y R2 U R U R2 U' R' U' R' U2 R'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "V"
          , [ "R' U R' d' R' F' R2 U' R' U R' F R F"
            , "R' U R' U' y R' F' R2 U' R' U R' F R F"
            , "R' U R' U' R D' R' D R' U D' R2 U' R2 D R2"
            , "z D' R2 D R2 U R' D' R U' R U R' D R U'"
            , "R U2 R' D R U' R U' R U R2 D R' U' R D2"
            , "y2 R U' R U R' D R D' R U' D R2 U R2 D' R2"
            , "R' U2 R U2 L U' R' U L' U L U' R U L'"
            , "R2 U' B2 U B2 R D' R D R' U R U' R"
            , "R2 D' R2 U R2 U' D R D' R D R' U R U' R"
            , "R' U R U' x' U R U2 R' U' R U' R' U2 R U R' U' x"
            , "y L' U R U' L U L' U R' U' L U2 R U2 R'"
            , "y2 R U' L' U R' U' R U' L U R' U2 L' U2 L"
            , "R2 U' f2 D f2 R D' R D R' U R U' R"
            , "y R F R2 U' R' U R' U' R2 U R F' R' U' R U R'"
            , "l' U R' D2 R U' R' D2 F R F' R U2 r' U r U2 x'"
            , "R' U R' U' R D' R' D R' B2 U' B2 U R2"
            , "R' U l' f' l' U l' B' l2 U' R' U R U"
            , "y R U R' U R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R U' R U' R'"
            , "R' U R' U' y x2 R' U R' U' x' R2 U' R' U R U"
            , "R' U R' U' R D' R' D R' y R2 U' R2 d R2"
            , "y R U R' U R U' R' U L' U2 R U2 R' U2 L R U2 R' U"
            , "R' U R' U' R D' R' D R' y R2 U' R2 U F2"
            , "R' U R' U' y x R' F R' F' R2 U' R' U R U"
            , "y' R' U L U' R U R' U L' U' R U2 L U2 L'"
            , "y R U2 R' U2 L' U R U' L U' L' U R' U' L"
            , "y2 L' U2 L U2 R U' L' U R' U R U' L U R'"
            , "y z U' R D R' U R U' R D' R' U R2 D R2 D' z'"
            , "y' z D' R U R' D R D' R U' R' D R2 U R2 U' z'"
            , "y' L U2 L' U2 R' U L U' R U' R' U L' U' R"
            , "R' U R' U' y x R' U' R2 B' R' B R' U R U"
            , "F R' U' R' F' U' F R U2 R U' R' F R2 F' R' F'"
            , "R U R D R' U' R D' R2 U2 R' U2 R' D' r U2 r' D R2"
            , "y' R U2 R u2 R U' R' D' R U R2 F2 R D' L2"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Y"
          , [ "F R U' R' U' R U R' F' R U R' U' R' F R F'"
            , "F R' F R2 U' R' U' R U R' F' R U R' U' F'"
            , "R2 U' R2 U' R2 U R' F' R U R2 U' R' F R"
            , "R2 D' R2 U R2 U' R2 D R2 U' R2 U R2 U R2"
            , "y2 R' U2 R' F' R2 U' R' F' U' F R U R' F U2 R"
            , "R' U' R F2 R' U R d R2 U' R2 U' R2"
            , "F R U' R' U' R U y' R U R' B' R U' R2"
            , "y F' L' U L U L' U' L F L' U' L U L F' L' F"
            , "R2 U' R' U R U' y' x' L' U' R U' R' U' L U"
            , "R2 U' R2 U' R2 U y' R U R' B2 R U' R'"
            , "F R U' R' U' R d R U R' B' R U' R2"
            , "F U F' R2 F U' F' U' R2 U R2 U R2"
            , "F R U r U2 R2 F R F' R U2 r' R' F'"
            , "R' U' R U' R U R' F' R U R' U' R' F R2 U' R2 U R"
            , "R' U' l D2 l' U R d R2 U' R2 U' R2"
            , "y' x' U' R U l' U' R' U R2 U R' U' R' F R F'"
            , "R2 U' R' U R U' x' U' z' U' R U' R' U' z U R x"
            , "R2 U' R' U R U' x' U' z' U' R U' R' U' L U x"
            , "F R U R U2 R' L' U R U' L U2 R2 F'"
            , "F R' F' R U R U' R' F R U' R' U R U R' F'"
            , "R' F' R U R' U' R' F R U' R U R2 D' R U R' D R2"
            , "x U R' U l R U' R' U' R U R' F' R U R' U' F'"
            , "F R' F' R U R U' R2 U' R U l U' R' U x"
            , "F R U r U2 R2 F R F' R U2 r' R' F'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        , ( "Z"
          , [ "M2 U M2 U M' U2 M2 U2 M'"
            , "y M2 U' M2 U' M' U2 M2 U2 M'"
            , "M' U' M2 U' M2 U' M' U2 M2"
            , "y R' U' R U' R U R U' R' U R U R2 U' R'"
            , "R' U' R2 U R U R' U' R U R U' R U' R'"
            , "y M' U M2 U M2 U M' U2 M2"
            , "R U R' U R' U' R' U R U' R' U' R2 U R"
            , "M2 U' M' U2 M2 U2 M' U M2"
            , "M2 U2 M U' M2 U' M2 U' M"
            , "M2 u M2 u' S M2 S'"
            , "M2 U M2 U' E2 M E2 M"
            , "R2 U R2 U2 R2 U R2 U' R2 U R2 U2 R2 U R2"
            , "M2 U2 M' U' M2 U' M2 U' M'"
            , "y M2 U' M2 U' M' U2 M2 U2 M' U2"
            , "M2 U M2 U M' U2 M2 U2 M'"
            , "R2 U R2 U R U2 R2 U2 R2 U2 R U' R2 U' R2"
            , "M2 U M2 U x' U2 M2 U2 M2"
            , "S2 D' M E2 M D' U2 S2"
            , "M2 U2 M' U M2 U M2 U M'"
            , "y M2 U' M2 U' M U2 M2 U2 M U2"
            , "F' L' U' L U F R' U' F R' F' R U R"
            , "y F R U R' U' F' L U F' r U r' U' L'"
            , "M' U2 M2 U2 M' U' M2 U' M2"
            , "y R U R2 U' R' U' R U R' U' R' U R' U R"
            , "M2 U M2 U x M2 U2 M2 U2"
            , "M' U2 M2 U2 M' U' M2 U' M2"
            , "x' R U' R' U D R' D U' R' U R D2"
            , "R2 U' R2 U' R2 U' R2 U' R2 U' S R2 S'"
            ]
                |> List.map (Algorithm.fromString >> Result.withDefault Algorithm.empty)
          )
        ]
