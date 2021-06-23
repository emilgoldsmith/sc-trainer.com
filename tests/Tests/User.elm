module Tests.User exposing (serializationTests)

import Algorithm exposing (Algorithm)
import Expect
import Fuzz
import Json.Decode
import Json.Encode
import List.Nonempty
import PLL exposing (PLL)
import Test exposing (..)
import User exposing (User)


serializationTests : Test
serializationTests =
    describe "serialization"
        [ fuzz userFuzzer "serializing a user followed by deserializing produces the original user" <|
            \user ->
                user
                    |> User.serialize
                    |> User.deserialize
                    |> Expect.equal (Ok user)
        , test "deserializing null fails" <|
            \_ ->
                User.deserialize Json.Encode.null
                    |> Expect.err
        , fuzz Fuzz.string "deserializing a random string fails" <|
            \string ->
                User.deserialize (Json.Encode.string string)
                    |> Expect.err
        , describe "Ensure Backwards Compatibility"
            [ test "it still works for the first format" <|
                \_ ->
                    let
                        fixture =
                            Result.withDefault Json.Encode.null <|
                                Json.Decode.decodeString Json.Decode.value "{\"usersCurrentPLLAlgorithms\":{\"H\":\"R2 U2 R U2 R2 U2 R2 U2 R U2 R2\",\"Ua\":\"F2 U' L R' F2 L' R U' F2\",\"Ub\":\"F2 U R' L F2 R L' U F2\",\"Z\":\"R B' R' B F R' F B' R' B R F2\",\"Aa\":\"R' F R' B2 R F' R' B2 R2\",\"Ab\":\"R B' R F2 R' B R F2 R2\",\"E\":\"D R' D2 F' D L D' F D2 R D' F' L' F\",\"F\":\"L F R' F' L' F' D2 B' L' B D2 F' R F2\",\"Ga\":\"F2' D R' U R' U' R D' F2 L' U L\",\"Gb\":\"R' U' R B2 D L' U L U' L D' B2\",\"Gc\":\"R2' D' F U' F U F' D R2 B U' B'\",\"Gd\":\"R U R' F2 D' L U' L' U L' D F2\",\"Ja\":\"B2 R' U' R B2 L' D L' D' L2\",\"Jb\":\"B2 L U L' B2 R D' R D R2\",\"Na\":\"L U' R U2 L' U R' L U' R U2 L' U R'\",\"Nb\":\"R' U L' U2 R U' L R' U L' U2 R U' L\",\"Ra\":\"F2 R' F' U' F' U F R F' U2 F U2 F'\",\"Rb\":\"R2 F R U R U' R' F' R U2 R' U2 R\",\"T\":\"F2 D R2 U' R2 F2 D' L2 U L2\",\"V\":\"R' U R' U' B' R' B2 U' B' U B' R B R\",\"Y\":\"F2 D R2 U R2 D' R' U' R F2 R' U R\"}}"
                    in
                    User.deserialize fixture
                        |> Expect.ok
            ]
        ]


userFuzzer : Fuzz.Fuzzer User
userFuzzer =
    let
        changePllOperations =
            Fuzz.list (Fuzz.tuple ( pllFuzzer, algorithmFuzzer ))
                |> Fuzz.map
                    (List.map
                        (\( pll, algorithm ) ->
                            User.changePLLAlgorithm pll algorithm
                        )
                    )
    in
    changePllOperations
        |> Fuzz.map
            (List.foldl
                (\operation user -> operation user)
                User.new
            )


algorithmFuzzer : Fuzz.Fuzzer Algorithm
algorithmFuzzer =
    let
        turnFuzzer =
            Fuzz.map3
                Algorithm.Turn
                (nonEmptyListToFuzzer Algorithm.allTurnables)
                (nonEmptyListToFuzzer Algorithm.allTurnLengths)
                (nonEmptyListToFuzzer Algorithm.allTurnDirections)

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


pllFuzzer : Fuzz.Fuzzer PLL
pllFuzzer =
    nonEmptyListToFuzzer PLL.all


nonEmptyListToFuzzer : List.Nonempty.Nonempty a -> Fuzz.Fuzzer a
nonEmptyListToFuzzer =
    List.Nonempty.toList >> listToFuzzer


listToFuzzer : List a -> Fuzz.Fuzzer a
listToFuzzer list =
    Fuzz.oneOf <| List.map Fuzz.constant list
