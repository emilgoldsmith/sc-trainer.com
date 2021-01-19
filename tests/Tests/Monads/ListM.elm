module Tests.Monads.ListM exposing (suite)

import Expect
import Fuzz
import Monads.ListM as ListM
import Test exposing (..)


suite : Test
suite =
    describe "Monads.List"
        [ describe "applicative"
            [ fuzz2 (Fuzz.list Fuzz.int) (Fuzz.list Fuzz.int) "Handles nondeterminism correctly, taking the cartesian product with a single function" <|
                \ints1 ints2 ->
                    ListM.return (+)
                        |> ListM.applicative (ListM.fromList ints1)
                        |> ListM.applicative (ListM.fromList ints2)
                        |> (ListM.toList >> List.length)
                        |> Expect.equal
                            (List.length ints1
                                * List.length ints2
                            )
            , fuzz2 (Fuzz.list Fuzz.int) (Fuzz.list Fuzz.int) "Handles nondeterminsm correctly, taking the cartesian product with several functions" <|
                \ints1 ints2 ->
                    ListM.fromList [ (+), (-) ]
                        |> ListM.applicative (ListM.fromList ints1)
                        |> ListM.applicative (ListM.fromList ints2)
                        |> (ListM.toList >> List.length)
                        |> Expect.equal (2 * List.length ints1 * List.length ints2)
            , test "executes a specific example as expected" <|
                \_ ->
                    ListM.fromList [ (+), (-) ]
                        |> ListM.applicative (ListM.fromList [ 1, 2 ])
                        |> ListM.applicative (ListM.fromList [ 3, 4, 5 ])
                        |> ListM.toList
                        |> Expect.equalLists [ 4, 5, 6, 5, 6, 7, -2, -3, -4, -1, -2, -3 ]
            ]
        ]
