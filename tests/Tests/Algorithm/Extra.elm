module Tests.Algorithm.Extra exposing (catpsTests, complexityTests)

import AUF
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
            (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf)
            (Fuzz.intRange 1 100000000)
            "it's just complexity per second"
          <|
            \algorithm aufs milliseconds ->
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = milliseconds } aufs algorithm
                    |> Expect.within (Expect.Absolute 0.0000000001)
                        (Algorithm.Extra.complexity aufs algorithm / (toFloat milliseconds / 1000))
        , fuzz2 Fuzz.Extra.algorithmWithoutTPSIgnoredTurns
            (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf)
            "same algorithm executed in slower time should give lower catps"
          <|
            \algorithm aufs ->
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 2000 } aufs algorithm
                    |> Expect.lessThan
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } aufs algorithm)
        ]


complexityTests : Test
complexityTests =
    describe "complexity"
        [ fuzz3
            (Fuzz.pair
                Fuzz.Extra.algorithm
                (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf)
            )
            (Fuzz.pair Fuzz.Extra.turnLength Fuzz.Extra.turnDirection)
            (Fuzz.pair Fuzz.Extra.turnLength Fuzz.Extra.turnDirection)
            "y rotations in start and beginning don't affect complexity"
          <|
            \( algorithm, aufs ) ( length1, direction1 ) ( length2, direction2 ) ->
                let
                    withYRotationsAlgorithm =
                        Algorithm.append
                            (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.Y length1 direction1 ])
                        <|
                            Algorithm.append
                                algorithm
                                (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.Y length2 direction2 ])
                in
                Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } aufs withYRotationsAlgorithm
                    |> Expect.within (Expect.Absolute 0.0000001)
                        (Algorithm.Extra.complexityAdjustedTPS { milliseconds = 1000 } aufs algorithm)
        , fuzz2 Fuzz.Extra.algorithm
            (Fuzz.pair Fuzz.Extra.auf Fuzz.Extra.auf)
            "adding a turn increases complexity"
          <|
            \algorithm aufs ->
                let
                    withTurnAdded =
                        Algorithm.append
                            algorithm
                            (Algorithm.fromTurnList [ Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise ])
                in
                Algorithm.Extra.complexity aufs withTurnAdded
                    |> Expect.greaterThan
                        (Algorithm.Extra.complexity aufs algorithm)
        , test "Satisfies the complexity baseline, which is that a U turn is 1 complexity" <|
            \_ ->
                Algorithm.Extra.complexity ( AUF.None, AUF.None )
                    (Algorithm.fromTurnList
                        [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]
                    )
                    |> Expect.within (Expect.Absolute 0.00000001) 1
        ]
