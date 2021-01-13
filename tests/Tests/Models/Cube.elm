module Tests.Models.Cube exposing (..)

import Expect
import Models.Cube as Cube
import Test exposing (..)


suit : Test
suit =
    describe "Models.Cube"
        [ describe "applyAlgorithm"
            [ test "correctly applies cube" <|
                \_ ->
                    let
                        algorithm =
                            Cube.algFromString "U"

                        expectedCubeState =
                            Ok Cube.solved
                    in
                    Result.map2 Cube.applyAlgorithm algorithm (Ok Cube.solved)
                        |> Expect.equal expectedCubeState
            ]
        ]
