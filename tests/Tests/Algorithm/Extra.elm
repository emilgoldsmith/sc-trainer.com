module Tests.Algorithm.Extra exposing (catpsTests, complexityTests)

import Algorithm
import Algorithm.Extra
import Expect
import Fuzz
import Fuzz.Extra
import Test exposing (..)


catpsTests : Test
catpsTests =
    describe "complexityAdjustedTPS"
        [ fuzz2 Fuzz.Extra.algorithm (Fuzz.floatRange 1 100000000) "it's just complexity per second" <|
            \algorithm milliseconds ->
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = milliseconds } algorithm
                    |> Expect.within (Expect.Absolute 0.0000000001)
                        (Algorithm.Extra.complexity algorithm / (milliseconds / 1000))
        , fuzz Fuzz.Extra.algorithmWithoutTPSIgnoredMoves "same algorithm executed in slower time should give lower catps" <|
            \algorithm ->
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 2000 } algorithm
                    |> Expect.lessThan
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } algorithm)
        ]


complexityTests : Test
complexityTests =
    describe "complexity"
        [ fuzz3 Fuzz.Extra.algorithm
            (Fuzz.tuple ( Fuzz.Extra.turnLength, Fuzz.Extra.turnDirection ))
            (Fuzz.tuple ( Fuzz.Extra.turnLength, Fuzz.Extra.turnDirection ))
            "y rotations in start and beginning don't affect complexity"
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
        , fuzz Fuzz.Extra.algorithm "adding a turn increases complexity" <|
            \algorithm ->
                let
                    withTurnAdded =
                        Algorithm.append algorithm (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise ])
                in
                Algorithm.Extra.complexity withTurnAdded
                    |> Expect.greaterThan
                        (Algorithm.Extra.complexity algorithm)
        , test "Satisfies the reference of 1 complexity, which is a U turn" <|
            \_ ->
                Algorithm.Extra.complexity
                    (Algorithm.fromTurnList
                        [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]
                    )
                    |> Expect.within (Expect.Absolute 0.00000001) 1
        ]
