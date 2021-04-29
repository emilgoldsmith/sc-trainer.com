module Tests.Placeholder exposing (suite)

import Expect
import Test exposing (..)


suite : Test
suite =
    describe "placeholder" [ test "1 + 1 == 2" <| \_ -> 1 + 1 |> Expect.equal 2 ]
