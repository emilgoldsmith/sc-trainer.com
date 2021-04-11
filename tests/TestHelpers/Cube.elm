module TestHelpers.Cube exposing (compareCubeRenderings, cubeFuzzer, plainCubie, solvedCubeRendering)

import Cube exposing (Color(..))
import Fuzz


compareCubeRenderings : Cube.Rendering -> Cube.Rendering -> String
compareCubeRenderings a b =
    if a == b then
        "There are no differences"

    else
        let
            diffs =
                List.filterMap identity
                    [ compareCubieRenderings "ufr: " a.ufr b.ufr
                    , compareCubieRenderings "ufl: " a.ufl b.ufl
                    , compareCubieRenderings "ubl: " a.ubl b.ubl
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


plainCubie : Cube.CubieRendering
plainCubie =
    { u = PlasticColor, d = PlasticColor, f = PlasticColor, b = PlasticColor, l = PlasticColor, r = PlasticColor }


cubeFuzzer : Fuzz.Fuzzer Cube.Cube
cubeFuzzer =
    Fuzz.constant Cube.solved
