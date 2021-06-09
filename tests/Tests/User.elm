module Tests.User exposing (serializationTests)

import Algorithm exposing (Algorithm)
import Expect
import Fuzz
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

        -- , describe "Ensure Backwards Compatibility" [
        -- ]
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
                (listToFuzzer Algorithm.allTurnables)
                (listToFuzzer Algorithm.allTurnLengths)
                (listToFuzzer Algorithm.allTurnDirections)

        nonEmptyTurnList =
            Fuzz.map2 (::) turnFuzzer <| Fuzz.list turnFuzzer
    in
    Fuzz.map Algorithm.build nonEmptyTurnList


pllFuzzer : Fuzz.Fuzzer PLL
pllFuzzer =
    nonEmptyListToFuzzer PLL.all


nonEmptyListToFuzzer : List.Nonempty.Nonempty a -> Fuzz.Fuzzer a
nonEmptyListToFuzzer =
    List.Nonempty.toList >> listToFuzzer


listToFuzzer : List a -> Fuzz.Fuzzer a
listToFuzzer list =
    Fuzz.oneOf <| List.map Fuzz.constant list
