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
            , todo "Applying a quarter turn 2 <= x <= 4 times equals applying a double/triple/identity turn"
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
                        |> Expect.equal solvedCubeColors
            , test "U performs expected transformation" <|
                \_ ->
                    let
                        alg =
                            Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]

                        expectedColorSpec =
                            { solvedCubeColors | ufl = { plainCubie | u = UpColor, f = RightColor, l = FrontColor }, uf = { plainCubie | u = UpColor, f = RightColor }, ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor }, ur = { plainCubie | u = UpColor, r = BackColor }, ubr = { plainCubie | u = UpColor, b = LeftColor, r = BackColor }, ub = { plainCubie | u = UpColor, b = LeftColor }, ubl = { plainCubie | u = UpColor, b = LeftColor, l = FrontColor }, ul = { plainCubie | u = UpColor, l = FrontColor } }
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
                            { solvedCubeColors | dfl = { plainCubie | d = DownColor, f = LeftColor, l = BackColor }, df = { plainCubie | d = DownColor, f = LeftColor }, dfr = { plainCubie | d = DownColor, f = LeftColor, r = FrontColor }, dr = { plainCubie | d = DownColor, r = FrontColor }, dbr = { plainCubie | d = DownColor, b = RightColor, r = FrontColor }, db = { plainCubie | d = DownColor, b = RightColor }, dbl = { plainCubie | d = DownColor, b = RightColor, l = BackColor }, dl = { plainCubie | d = DownColor, l = BackColor } }
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
                            { solvedCubeColors | ubl = { plainCubie | u = BackColor, b = DownColor, l = LeftColor }, ul = { plainCubie | u = BackColor, l = LeftColor }, ufl = { plainCubie | u = BackColor, f = UpColor, l = LeftColor }, fl = { plainCubie | f = UpColor, l = LeftColor }, dfl = { plainCubie | d = FrontColor, f = UpColor, l = LeftColor }, dl = { plainCubie | d = FrontColor, l = LeftColor }, dbl = { plainCubie | d = FrontColor, b = DownColor, l = LeftColor }, bl = { plainCubie | b = DownColor, l = LeftColor } }
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
                            { solvedCubeColors | ufr = { plainCubie | u = FrontColor, f = DownColor, r = RightColor }, ur = { plainCubie | u = FrontColor, r = RightColor }, ubr = { plainCubie | u = FrontColor, b = UpColor, r = RightColor }, br = { plainCubie | b = UpColor, r = RightColor }, dbr = { plainCubie | d = BackColor, b = UpColor, r = RightColor }, dr = { plainCubie | d = BackColor, r = RightColor }, dfr = { plainCubie | d = BackColor, f = DownColor, r = RightColor }, fr = { plainCubie | f = DownColor, r = RightColor } }
                    in
                    Cube.solved
                        |> Cube.applyAlgorithm alg
                        |> Cube.render
                        |> Expect.equal expectedColorSpec
            , todo "F performs expected transformation"
            , todo "B performs expected transformation"
            , todo "M performs expected transformation"
            , todo "E performs expected transformation"
            , todo "S performs expected transformation"
            , test "0-length algorithm is identity operation to simplify types despite 0 length algorithm not making much sense" <| \_ -> Cube.solved |> Cube.applyAlgorithm (Algorithm.build []) |> Expect.equal Cube.solved
            ]
        ]


cubeFuzzer : Fuzz.Fuzzer Cube
cubeFuzzer =
    Fuzz.constant Cube.solved


plainCubie : Cube.CubieRendering
plainCubie =
    { u = PlasticColor, d = PlasticColor, f = PlasticColor, b = PlasticColor, l = PlasticColor, r = PlasticColor }


solvedCubeColors : Cube.Rendering
solvedCubeColors =
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
    }
