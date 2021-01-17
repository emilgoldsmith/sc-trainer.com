module Tests.Models.Cube exposing (suite)

import Expect
import Fuzz
import Models.Algorithm as Algorithm
import Models.Cube as Cube exposing (Color(..))
import Parser exposing ((|.), (|=))
import Test exposing (..)


suite : Test
suite =
    describe "Models.Cube"
        [ describe "applyAlgorithm"
            [ todo "Applying an algorithm followed by its inverse results in the identity"
            , todo "Applying a quarter move is not an identity operation"
            , todo "is associative, so we can split up and combine algs however we want without changing the result"
            , todo "is exactly commutative for parallel faces/slices"
            , todo "Applying a quarter turn 2 <= x <= 4 times equals applying a double/triple/identity turn"
            , todo "Applying a NUM (e.g double, triple) turn in one direction equals applying a (4 - NUM) turn in the opposite direction"
            , test "solved cube has correct colors" <|
                \_ ->
                    Cube.solved
                        |> Cube.render
                        |> Expect.equal solvedCubeColors
            , skip <|
                test "U performs expected transformation" <|
                    \_ ->
                        let
                            alg =
                                Algorithm.fromString "U"

                            expectedColorSpec =
                                Ok { solvedCubeColors | ufl = { plainCubie | u = UpColor, f = RightColor, l = FrontColor }, uf = { plainCubie | u = UpColor, f = RightColor }, ufr = { plainCubie | u = UpColor, f = RightColor, r = BackColor }, ur = { plainCubie | u = UpColor, r = BackColor }, ubr = { plainCubie | u = UpColor, b = LeftColor, r = BackColor }, ub = { plainCubie | u = UpColor, b = LeftColor }, ubl = { plainCubie | u = UpColor, b = LeftColor, l = FrontColor }, ul = { plainCubie | u = UpColor, l = FrontColor } }

                            actualColorSpec =
                                Ok Cube.solved
                                    |> Result.map2 Cube.applyAlgorithm alg
                                    |> Result.map Cube.render
                        in
                        actualColorSpec |> Expect.equal expectedColorSpec
            , todo "D performs expected transformation"
            , todo "F performs expected transformation"
            , todo "B performs expected transformation"
            , todo "L performs expected transformation"
            , todo "R performs expected transformation"
            , todo "M performs expected transformation"
            , todo "E performs expected transformation"
            , todo "S performs expected transformation"
            , test "0-length algorithm is identity operation to simplify types despite 0 length algorithm not making much sense" <| \_ -> Cube.solved |> Cube.applyAlgorithm (Algorithm.build []) |> Expect.equal Cube.solved
            ]
        ]


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
