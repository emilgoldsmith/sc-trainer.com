module Tests.Utils.NonEmptyList exposing (concatMapTests, singletonTests, toListTests)

import Expect
import Fuzz
import Test exposing (..)
import Utils.NonEmptyList as NonEmptyList exposing (NonEmptyList)


toListTests : Test
toListTests =
    describe "toList"
        [ test "correctly converts a simple list" <|
            \_ ->
                NonEmptyList.NonEmptyList 1 [ 2, 3, 4 ]
                    |> NonEmptyList.toList
                    |> Expect.equalLists [ 1, 2, 3, 4 ]
        , test "correctly converts singleton list" <|
            \_ ->
                NonEmptyList.NonEmptyList 8 []
                    |> NonEmptyList.toList
                    |> Expect.equalLists (List.singleton 8)
        ]


singletonTests : Test
singletonTests =
    describe "singleton"
        [ test "works for an arbitrary example" <|
            \_ ->
                NonEmptyList.singleton 3
                    |> Expect.equal (NonEmptyList.NonEmptyList 3 [])
        ]


concatMapTests : Test
concatMapTests =
    describe "concatMap"
        [ fuzz (fuzzNonEmptyList Fuzz.int) "preserves a list through singleton mapping" <|
            \list ->
                list
                    |> NonEmptyList.concatMap NonEmptyList.singleton
                    |> Expect.equal list
        , test "handles a more complex mapping function, and keeps them in correct order" <|
            \_ ->
                NonEmptyList.concatMap (\x -> NonEmptyList.NonEmptyList (x + 2) [ x + 3, x + 4 ]) (NonEmptyList.NonEmptyList 1 [ 2, 3 ])
                    |> Expect.equal (NonEmptyList.NonEmptyList 3 [ 4, 5, 4, 5, 6, 5, 6, 7 ])
        ]


fuzzNonEmptyList : Fuzz.Fuzzer a -> Fuzz.Fuzzer (NonEmptyList a)
fuzzNonEmptyList fuzzer =
    Fuzz.map2 NonEmptyList.NonEmptyList fuzzer (Fuzz.list fuzzer)
