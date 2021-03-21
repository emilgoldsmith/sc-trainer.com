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
        , test "Aa perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor } })
                            |> (\x -> { x | ubr = { plainCubie | u = UpColor, b = LeftColor, r = BackColor } })
                            |> (\x -> { x | ubl = { plainCubie | u = UpColor, b = FrontColor, l = RightColor } })
                in
                AlgorithmRepository.referencePlls.aa
                    |> expectEqualDisregardingAUF expectedRendering
        , test "Ab perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | ufr = { plainCubie | u = UpColor, f = BackColor, r = LeftColor } })
                            |> (\x -> { x | ubr = { plainCubie | u = UpColor, b = RightColor, r = FrontColor } })
                            |> (\x -> { x | ubl = { plainCubie | u = UpColor, b = RightColor, l = BackColor } })
                in
                AlgorithmRepository.referencePlls.ab
                    |> expectEqualDisregardingAUF expectedRendering
        , test "E perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor } })
                            |> (\x -> { x | ubr = { plainCubie | u = UpColor, b = RightColor, r = FrontColor } })
                            |> (\x -> { x | ubl = { plainCubie | u = UpColor, b = LeftColor, l = FrontColor } })
                            |> (\x -> { x | ufl = { plainCubie | u = UpColor, f = LeftColor, l = BackColor } })
                in
                AlgorithmRepository.referencePlls.e
                    |> expectEqualDisregardingAUF expectedRendering
        , test "F perm" <|
            \_ ->
                let
                    expectedRendering =
                        solvedCubeRendering
                            |> (\x -> { x | ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor } })
                            |> (\x -> { x | ubr = { plainCubie | u = UpColor, b = RightColor, r = FrontColor } })
                            |> (\x -> { x | ub = { plainCubie | u = UpColor, b = FrontColor } })
                            |> (\x -> { x | uf = { plainCubie | u = UpColor, f = BackColor } })
                in
                AlgorithmRepository.referencePlls.f
                    |> expectEqualDisregardingAUF expectedRendering
        ]


expectEqualDisregardingAUF : Cube.Rendering -> Algorithm -> Expect.Expectation
expectEqualDisregardingAUF expectedRendering alg =
    let
        candidates =
            Algorithm.withAllAufCombinations alg
                |> List.map ((\x -> Cube.applyAlgorithm x Cube.solved) >> Cube.render)
    in
    List.filter ((==) expectedRendering) candidates
        |> List.length
        |> Expect.greaterThan 0
        |> Expect.onFail
            ("Algorithm with or without AUF did not produce the expected rendering. Diffs for each AUF:"
                ++ "\n\n"
                ++ "(Actual != Expected)"
                ++ "\n\n"
                ++ (let
                        diffs =
                            List.map (\x -> compareCubeRenderings x expectedRendering) candidates
                    in
                    String.join "\n\n" diffs
                   )
            )


compareCubeRenderings : Cube.Rendering -> Cube.Rendering -> String
compareCubeRenderings a b =
    if a == b then
        "There are no differences"

    else
        let
            diffs =
                List.filterMap identity
                    [ compareCubieRenderings "ufr: " a.ufr b.ufr
                    , compareCubieRenderings "ufl " a.ufl b.ufl
                    , compareCubieRenderings "ubl " a.ubl b.ubl
                    , compareCubieRenderings "ubr: " a.ubr b.ubr
                    , compareCubieRenderings "dbr: " a.dbr b.dbr
                    , compareCubieRenderings "dbl: " a.dbl b.dbl
                    , compareCubieRenderings "dfl: " a.dfl b.dfl
                    , compareCubieRenderings "dfr: " a.dfr b.dfr
                    , compareCubieRenderings "uf: " a.uf b.uf
                    , compareCubieRenderings "ur: " a.ur b.ur
                    , compareCubieRenderings "ub: " a.ub b.ub
                    , compareCubieRenderings "ul: " a.ul b.ul
                    , compareCubieRenderings "fl: " a.fl b.fl
                    , compareCubieRenderings "fr: " a.fr b.fr
                    , compareCubieRenderings "br: " a.br b.br
                    , compareCubieRenderings "bl: " a.bl b.bl
                    , compareCubieRenderings "df: " a.df b.df
                    , compareCubieRenderings "dr: " a.dr b.dr
                    , compareCubieRenderings "db: " a.db b.db
                    , compareCubieRenderings "dl: " a.dl b.dl
                    , compareCubieRenderings "u: " a.u b.u
                    , compareCubieRenderings "d: " a.d b.d
                    , compareCubieRenderings "f: " a.f b.f
                    , compareCubieRenderings "b: " a.b b.b
                    , compareCubieRenderings "l: " a.l b.l
                    , compareCubieRenderings "r: " a.r b.r
                    ]
        in
        "{ " ++ String.join "\n, " diffs ++ "\n}"


compareCubieRenderings : String -> Cube.CubieRendering -> Cube.CubieRendering -> Maybe String
compareCubieRenderings prefix a b =
    if a == b then
        Nothing

    else
        let
            diffs =
                List.filterMap identity
                    [ compareCubieFaces "u: " a.u b.u
                    , compareCubieFaces "d: " a.d b.d
                    , compareCubieFaces "r: " a.r b.r
                    , compareCubieFaces "l: " a.l b.l
                    , compareCubieFaces "f: " a.f b.f
                    , compareCubieFaces "b: " a.b b.b
                    ]
        in
        Just <| prefix ++ "{ " ++ String.join ", " diffs ++ " }"


compareCubieFaces : String -> Cube.Color -> Cube.Color -> Maybe String
compareCubieFaces prefix a b =
    if a == b then
        Nothing

    else
        Just <| prefix ++ Debug.toString a ++ " != " ++ Debug.toString b
