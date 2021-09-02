module Tests.Algorithm.Extra exposing (catpsTests)

import Algorithm
import Algorithm.Extra
import Expect
import Fuzz
import Fuzz.Extra
import Test exposing (..)


catpsTests : Test
catpsTests =
    describe "complexityAdjustedTPS"
        [ fuzz3 Fuzz.Extra.algorithm
            (Fuzz.tuple ( Fuzz.Extra.turnLength, Fuzz.Extra.turnDirection ))
            (Fuzz.tuple ( Fuzz.Extra.turnLength, Fuzz.Extra.turnDirection ))
            "y rotations in start and beginning don't affect catps"
          <|
            \algorithm ( length1, direction1 ) ( length2, direction2 ) ->
                let
                    referenceAlgorithm =
                        algorithm

                    withYRotationsAlgorithm =
                        referenceAlgorithm
                            |> Algorithm.append
                                (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.Y length1 direction1 ])
                            |> (\alg ->
                                    Algorithm.append
                                        alg
                                        (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.Y length2 direction2 ])
                               )
                in
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } withYRotationsAlgorithm
                    |> Expect.within (Expect.Absolute 0.0000001)
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } algorithm)
        , fuzz Fuzz.Extra.algorithm "adding a turn with same time makes catps better (greater)" <|
            \algorithm ->
                let
                    withTurnAdded =
                        Algorithm.append algorithm (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise ])
                in
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } withTurnAdded
                    |> Expect.greaterThan
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } algorithm)
        , fuzz Fuzz.Extra.algorithmWithoutTPSIgnoredMoves "same algorithm executed in slower time should give lower catps" <|
            \algorithm ->
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 2000 } algorithm
                    |> Expect.lessThan
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } algorithm)
        , test "Satisfies the reference of a TPS, which is a U turn" <|
            \_ ->
                Algorithm.Extra.complexityAdjustedTPS
                    { milliseconds = 1000 }
                    (Algorithm.fromTurnList
                        [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]
                    )
                    |> Expect.within (Expect.Absolute 0.00000001) 1
        ]
