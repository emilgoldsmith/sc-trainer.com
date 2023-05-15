module Tests.List.Nonempty.Extra exposing (getPreferredEquivalentAUFsTests)

import Expect
import List.Nonempty
import List.Nonempty.Extra
import Test exposing (..)


getPreferredEquivalentAUFsTests : Test
getPreferredEquivalentAUFsTests =
    describe "allMinimums"
        [ test "solves a complicated example correctly" <|
            \_ ->
                List.Nonempty.Nonempty 3 [ 5, 2, 1342, -10, 2, 0, 543, -10, 234 ]
                    |> List.Nonempty.Extra.allMinimums compare
                    |> List.Nonempty.toList
                    |> Expect.equalLists [ -10, -10 ]
        , test "solves a singleton correctly" <|
            \_ ->
                List.Nonempty.singleton 34
                    |> List.Nonempty.Extra.allMinimums compare
                    |> List.Nonempty.toList
                    |> Expect.equalLists [ 34 ]
        ]
