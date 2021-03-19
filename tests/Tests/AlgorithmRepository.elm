module Tests.AlgorithmRepository exposing (pllTests)

import AlgorithmRepository
import Expect
import Models.Algorithm as Algorithm exposing (Algorithm)
import Models.Cube as Cube exposing (Color(..))
import Test exposing (..)
import Tests.Models.Cube exposing (plainCubie, solvedCubeRendering)


pllTests : Test
pllTests =
    describe "PLL"
        [ test "H perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | uf = { plainCubie | u = UpColor, f = BackColor } })
                            |> (\x -> { x | ub = { plainCubie | u = UpColor, b = FrontColor } })
                            |> (\x -> { x | ul = { plainCubie | u = UpColor, l = RightColor } })
                            |> (\x -> { x | ur = { plainCubie | u = UpColor, r = LeftColor } })
                in
                AlgorithmRepository.referencePlls.h
                    |> expectEqualDisregardingAUF expectedRendering
        , test "Ua perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | uf = { plainCubie | u = UpColor, f = LeftColor } })
                            |> (\x -> { x | ur = { plainCubie | u = UpColor, r = FrontColor } })
                            |> (\x -> { x | ul = { plainCubie | u = UpColor, l = RightColor } })
                in
                AlgorithmRepository.referencePlls.ua
                    |> expectEqualDisregardingAUF expectedRendering
        , test "Ub perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | uf = { plainCubie | u = UpColor, f = RightColor } })
                            |> (\x -> { x | ul = { plainCubie | u = UpColor, l = FrontColor } })
                            |> (\x -> { x | ur = { plainCubie | u = UpColor, r = LeftColor } })
                in
                AlgorithmRepository.referencePlls.ub
                    |> expectEqualDisregardingAUF expectedRendering
        , test "Z perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | uf = { plainCubie | u = UpColor, f = RightColor } })
                            |> (\x -> { x | ur = { plainCubie | u = UpColor, r = FrontColor } })
                            |> (\x -> { x | ul = { plainCubie | u = UpColor, l = BackColor } })
                            |> (\x -> { x | ub = { plainCubie | u = UpColor, b = LeftColor } })
                in
                AlgorithmRepository.referencePlls.z
                    |> expectEqualDisregardingAUF expectedRendering
        ]


expectEqualDisregardingAUF : Cube.Rendering -> Algorithm -> Expect.Expectation
expectEqualDisregardingAUF expectedRendering alg =
    let
        candidates =
            List.map (Algorithm.appendTo alg)
                [ Algorithm.build []
                , Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise ]
                , Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise ]
                , Algorithm.build [ Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise ]
                ]
                |> List.map ((\x -> Cube.applyAlgorithm x Cube.solved) >> Cube.render)
    in
    List.filter ((==) expectedRendering) candidates
        |> List.length
        |> Expect.greaterThan 0
        |> Expect.onFail
            ("Algorithm with or without AUF did not produce the expected rendering"
                ++ "\n\n"
                ++ Debug.toString alg
                ++ "\n\n"
                ++ Debug.toString expectedRendering
            )
