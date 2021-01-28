module Tests.Models.Cube exposing (suite)

import Expect
import Fuzz
import Models.Algorithm as Algorithm
import Models.Cube as Cube exposing (Color(..), Cube)
import Parser exposing ((|.), (|=))
import Test exposing (..)
import Tests.Models.Algorithm exposing (algorithmFuzzer, turnDirectionFuzzer, turnFuzzer, turnableFuzzer)


suite : Test
suite =
    describe "Models.Cube"
        [ describe "applyAlgorithm"
            [ fuzz2 cubeFuzzer algorithmFuzzer "Applying an algorithm followed by its inverse results in the identity" <|
                \cube alg ->
                    cube
                        |> Cube.applyAlgorithm alg
                        |> Cube.applyAlgorithm (Algorithm.inverse alg)
                        |> Expect.equal cube
            , fuzz2 cubeFuzzer turnFuzzer "Applying a single move is not an identity operation" <|
                \cube turn ->
                    cube
                        |> Cube.applyAlgorithm (Algorithm.build << List.singleton <| turn)
                        |> Expect.notEqual cube
            , fuzz3 cubeFuzzer algorithmFuzzer algorithmFuzzer "is associative, so applying combined or separated algs to cube should result in same cube" <|
                \cube alg1 alg2 ->
                    let
                        appliedTogether =
                            cube |> Cube.applyAlgorithm (Algorithm.appendTo alg1 alg2)

                        appliedSeparately =
                            cube |> Cube.applyAlgorithm alg1 |> Cube.applyAlgorithm alg2
                    in
                    appliedTogether |> Expect.equal appliedSeparately
            , todo "is exactly commutative for parallel faces/slices"
            , fuzz3 cubeFuzzer turnableFuzzer turnDirectionFuzzer "Applying a quarter turn twice equals applying a double turn" <|
                \cube turnable direction ->
                    let
                        quarterTurn =
                            Algorithm.Turn turnable Algorithm.OneQuarter direction

                        doubleTurn =
                            Algorithm.Turn turnable Algorithm.Halfway direction

                        afterTwoQuarterTurns =
                            cube |> Cube.applyAlgorithm (Algorithm.build [ quarterTurn, quarterTurn ])

                        afterOneHalfway =
                            cube |> Cube.applyAlgorithm (Algorithm.build [ doubleTurn ])
                    in
                    afterTwoQuarterTurns |> Expect.equal afterOneHalfway
            , fuzz3 cubeFuzzer turnableFuzzer turnDirectionFuzzer "Applying a quarter turn thrice equals applying a triple turn" <|
                \cube turnable direction ->
                    let
                        quarterTurn =
                            Algorithm.Turn turnable Algorithm.OneQuarter direction

                        tripleTurn =
                            Algorithm.Turn turnable Algorithm.ThreeQuarters direction

                        afterThreeQuarterTurns =
                            cube |> Cube.applyAlgorithm (Algorithm.build [ quarterTurn, quarterTurn, quarterTurn ])

                        afterOneTripleTurn =
                            cube |> Cube.applyAlgorithm (Algorithm.build [ tripleTurn ])
                    in
                    afterThreeQuarterTurns |> Expect.equal afterOneTripleTurn
            , fuzz3 cubeFuzzer turnableFuzzer turnDirectionFuzzer "Applying a quarter turn four times equals doing nothing" <|
                \cube turnable direction ->
                    let
                        quarterTurn =
                            Algorithm.Turn turnable Algorithm.OneQuarter direction

                        afterFourQuarterTurns =
                            cube |> Cube.applyAlgorithm (Algorithm.build [ quarterTurn, quarterTurn, quarterTurn, quarterTurn ])
                    in
                    afterFourQuarterTurns |> Expect.equal cube
            , fuzz2 cubeFuzzer turnFuzzer "Applying a NUM (e.g double, triple) turn in one direction equals applying a (4 - NUM) turn in the opposite direction" <|
                \cube ((Algorithm.Turn turnable length direction) as turn) ->
                    let
                        flipDirection dir =
                            case dir of
                                Algorithm.Clockwise ->
                                    Algorithm.CounterClockwise

                                Algorithm.CounterClockwise ->
                                    Algorithm.Clockwise

                        flipLength len =
                            case len of
                                Algorithm.OneQuarter ->
                                    Algorithm.ThreeQuarters

                                Algorithm.Halfway ->
                                    Algorithm.Halfway

                                Algorithm.ThreeQuarters ->
                                    Algorithm.OneQuarter

                        turnAlg =
                            Algorithm.build << List.singleton <| turn

                        oppositeDirectionEquivalent =
                            Algorithm.build << List.singleton <| Algorithm.Turn turnable (flipLength length) (flipDirection direction)
                    in
                    cube |> Cube.applyAlgorithm turnAlg |> Expect.equal (Cube.applyAlgorithm oppositeDirectionEquivalent cube)
            , test "solved cube has correct colors" <|
                \_ ->
                    Cube.solved
                        |> Cube.render
                        |> Expect.equal solvedCubeRendering
            , test "U performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor } })
                                |> (\x -> { x | uf = { plainCubie | u = UpColor, f = RightColor } })
                                |> (\x -> { x | ufl = { plainCubie | u = UpColor, f = RightColor, l = FrontColor } })
                                |> (\x -> { x | ul = { plainCubie | u = UpColor, l = FrontColor } })
                                |> (\x -> { x | ubl = { plainCubie | u = UpColor, b = LeftColor, l = FrontColor } })
                                |> (\x -> { x | ub = { plainCubie | u = UpColor, b = LeftColor } })
                                |> (\x -> { x | ubr = { plainCubie | u = UpColor, b = LeftColor, r = BackColor } })
                                |> (\x -> { x | ur = { plainCubie | u = UpColor, r = BackColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "D performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | dfl = { plainCubie | d = DownColor, f = LeftColor, l = BackColor } })
                                |> (\x -> { x | df = { plainCubie | d = DownColor, f = LeftColor } })
                                |> (\x -> { x | dfr = { plainCubie | d = DownColor, f = LeftColor, r = FrontColor } })
                                |> (\x -> { x | dr = { plainCubie | d = DownColor, r = FrontColor } })
                                |> (\x -> { x | dbr = { plainCubie | d = DownColor, b = RightColor, r = FrontColor } })
                                |> (\x -> { x | db = { plainCubie | d = DownColor, b = RightColor } })
                                |> (\x -> { x | dbl = { plainCubie | d = DownColor, b = RightColor, l = BackColor } })
                                |> (\x -> { x | dl = { plainCubie | d = DownColor, l = BackColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "L performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ubl = { plainCubie | u = BackColor, b = DownColor, l = LeftColor } })
                                |> (\x -> { x | ul = { plainCubie | u = BackColor, l = LeftColor } })
                                |> (\x -> { x | ufl = { plainCubie | u = BackColor, f = UpColor, l = LeftColor } })
                                |> (\x -> { x | fl = { plainCubie | f = UpColor, l = LeftColor } })
                                |> (\x -> { x | dfl = { plainCubie | d = FrontColor, f = UpColor, l = LeftColor } })
                                |> (\x -> { x | dl = { plainCubie | d = FrontColor, l = LeftColor } })
                                |> (\x -> { x | dbl = { plainCubie | d = FrontColor, b = DownColor, l = LeftColor } })
                                |> (\x -> { x | bl = { plainCubie | b = DownColor, l = LeftColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "R performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ufr = { plainCubie | u = FrontColor, f = DownColor, r = RightColor } })
                                |> (\x -> { x | ur = { plainCubie | u = FrontColor, r = RightColor } })
                                |> (\x -> { x | ubr = { plainCubie | u = FrontColor, b = UpColor, r = RightColor } })
                                |> (\x -> { x | br = { plainCubie | b = UpColor, r = RightColor } })
                                |> (\x -> { x | dbr = { plainCubie | d = BackColor, b = UpColor, r = RightColor } })
                                |> (\x -> { x | dr = { plainCubie | d = BackColor, r = RightColor } })
                                |> (\x -> { x | dfr = { plainCubie | d = BackColor, f = DownColor, r = RightColor } })
                                |> (\x -> { x | fr = { plainCubie | f = DownColor, r = RightColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "F performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ufl = { plainCubie | u = LeftColor, f = FrontColor, l = DownColor } })
                                |> (\x -> { x | uf = { plainCubie | u = LeftColor, f = FrontColor } })
                                |> (\x -> { x | ufr = { plainCubie | u = LeftColor, f = FrontColor, r = UpColor } })
                                |> (\x -> { x | fr = { plainCubie | f = FrontColor, r = UpColor } })
                                |> (\x -> { x | dfr = { plainCubie | d = RightColor, f = FrontColor, r = UpColor } })
                                |> (\x -> { x | df = { plainCubie | d = RightColor, f = FrontColor } })
                                |> (\x -> { x | dfl = { plainCubie | d = RightColor, f = FrontColor, l = DownColor } })
                                |> (\x -> { x | fl = { plainCubie | f = FrontColor, l = DownColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "B performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ubr = { plainCubie | u = RightColor, b = BackColor, r = DownColor } })
                                |> (\x -> { x | ub = { plainCubie | u = RightColor, b = BackColor } })
                                |> (\x -> { x | ubl = { plainCubie | u = RightColor, b = BackColor, l = UpColor } })
                                |> (\x -> { x | bl = { plainCubie | b = BackColor, l = UpColor } })
                                |> (\x -> { x | dbl = { plainCubie | d = LeftColor, b = BackColor, l = UpColor } })
                                |> (\x -> { x | db = { plainCubie | d = LeftColor, b = BackColor } })
                                |> (\x -> { x | dbr = { plainCubie | d = LeftColor, b = BackColor, r = DownColor } })
                                |> (\x -> { x | br = { plainCubie | b = BackColor, r = DownColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "M performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.M Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ub = { plainCubie | u = BackColor, b = DownColor } })
                                |> (\x -> { x | u = { plainCubie | u = BackColor } })
                                |> (\x -> { x | uf = { plainCubie | u = BackColor, f = UpColor } })
                                |> (\x -> { x | f = { plainCubie | f = UpColor } })
                                |> (\x -> { x | df = { plainCubie | d = FrontColor, f = UpColor } })
                                |> (\x -> { x | d = { plainCubie | d = FrontColor } })
                                |> (\x -> { x | db = { plainCubie | d = FrontColor, b = DownColor } })
                                |> (\x -> { x | b = { plainCubie | b = DownColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "S performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.S Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | ul = { plainCubie | u = LeftColor, l = DownColor } })
                                |> (\x -> { x | u = { plainCubie | u = LeftColor } })
                                |> (\x -> { x | ur = { plainCubie | u = LeftColor, r = UpColor } })
                                |> (\x -> { x | r = { plainCubie | r = UpColor } })
                                |> (\x -> { x | dr = { plainCubie | d = RightColor, r = UpColor } })
                                |> (\x -> { x | d = { plainCubie | d = RightColor } })
                                |> (\x -> { x | dl = { plainCubie | d = RightColor, l = DownColor } })
                                |> (\x -> { x | l = { plainCubie | l = DownColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "E performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.E Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            solvedCubeRendering
                                |> (\x -> { x | fl = { plainCubie | f = LeftColor, l = BackColor } })
                                |> (\x -> { x | f = { plainCubie | f = LeftColor } })
                                |> (\x -> { x | fr = { plainCubie | f = LeftColor, r = FrontColor } })
                                |> (\x -> { x | r = { plainCubie | r = FrontColor } })
                                |> (\x -> { x | br = { plainCubie | b = RightColor, r = FrontColor } })
                                |> (\x -> { x | b = { plainCubie | b = RightColor } })
                                |> (\x -> { x | bl = { plainCubie | b = RightColor, l = BackColor } })
                                |> (\x -> { x | l = { plainCubie | l = BackColor } })
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , test "0-length algorithm is identity operation to simplify types despite 0 length algorithm not making much sense" <|
                \_ ->
                    Cube.solved |> Cube.applyAlgorithm (Algorithm.build []) |> Expect.equal Cube.solved
            ]
        ]


cubeFuzzer : Fuzz.Fuzzer Cube
cubeFuzzer =
    Fuzz.constant Cube.solved


plainCubie : Cube.CubieRendering
plainCubie =
    { u = PlasticColor, d = PlasticColor, f = PlasticColor, b = PlasticColor, l = PlasticColor, r = PlasticColor }


solvedCubeRendering : Cube.Rendering
solvedCubeRendering =
    { -- U Corners
      ufr = { plainCubie | u = UpColor, f = FrontColor, r = RightColor }
    , ufl = { plainCubie | u = UpColor, f = FrontColor, l = LeftColor }
    , ubl = { plainCubie | u = UpColor, b = BackColor, l = LeftColor }
    , ubr = { plainCubie | u = UpColor, b = BackColor, r = RightColor }

    -- D Corners
    , dbr = { plainCubie | d = DownColor, b = BackColor, r = RightColor }
    , dbl = { plainCubie | d = DownColor, b = BackColor, l = LeftColor }
    , dfl = { plainCubie | d = DownColor, f = FrontColor, l = LeftColor }
    , dfr = { plainCubie | d = DownColor, f = FrontColor, r = RightColor }

    -- M Edges
    , uf = { plainCubie | u = UpColor, f = FrontColor }
    , ub = { plainCubie | u = UpColor, b = BackColor }
    , db = { plainCubie | d = DownColor, b = BackColor }
    , df = { plainCubie | d = DownColor, f = FrontColor }

    -- S Edges
    , dl = { plainCubie | d = DownColor, l = LeftColor }
    , dr = { plainCubie | d = DownColor, r = RightColor }
    , ur = { plainCubie | u = UpColor, r = RightColor }
    , ul = { plainCubie | u = UpColor, l = LeftColor }

    -- E Edges
    , fl = { plainCubie | f = FrontColor, l = LeftColor }
    , fr = { plainCubie | f = FrontColor, r = RightColor }
    , br = { plainCubie | b = BackColor, r = RightColor }
    , bl = { plainCubie | b = BackColor, l = LeftColor }

    -- Centers
    , u = { plainCubie | u = UpColor }
    , d = { plainCubie | d = DownColor }
    , f = { plainCubie | f = FrontColor }
    , b = { plainCubie | b = BackColor }
    , l = { plainCubie | l = LeftColor }
    , r = { plainCubie | r = RightColor }
    }
