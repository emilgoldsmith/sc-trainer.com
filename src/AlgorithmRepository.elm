module AlgorithmRepository exposing (PLL, referencePlls)

import Models.Algorithm as Algorithm exposing (Algorithm)


type alias PLL =
    { -- Edges only
      h : Algorithm
    , ua : Algorithm
    , ub : Algorithm
    , z : Algorithm
    , aa : Algorithm
    , ab : Algorithm
    , e : Algorithm
    , f : Algorithm
    , ga : Algorithm
    , gb : Algorithm
    , gc : Algorithm
    , gd : Algorithm
    , ja : Algorithm
    , jb : Algorithm
    , na : Algorithm
    , nb : Algorithm
    , ra : Algorithm
    , rb : Algorithm
    , t : Algorithm
    , v : Algorithm
    , y : Algorithm
    }


{-| Plls verified to be correct so they can be used to verify user selected plls
or for displaying a pll case somewhere on the site.
They have been chosen to be the optimally lowest move count in HTM just for a
small performance boost. The example tests below are just meant for an easier
to read version of all the algorithms that are verified to be correct

    import Models.Algorithm

    Models.Algorithm.fromString "R2 U2 R U2 R2 U2 R2 U2 R U2 R2"
    --> Ok referencePlls.h

    Models.Algorithm.fromString "F2 U' (L R') F2 (L' R) U' F2"
    --> Ok referencePlls.ua

    Models.Algorithm.fromString "F2 U (R' L) F2 (R L') U F2"
    --> Ok referencePlls.ub

    Models.Algorithm.fromString "R B' R' B F R' F B' R' B R F2"
    --> Ok referencePlls.z

-}
referencePlls : PLL
referencePlls =
    { h =
        Algorithm.build
            [ Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            ]
    , ua =
        Algorithm.build
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            ]
    , ub =
        Algorithm.build
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            ]
    , z =
        Algorithm.build
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            ]
    , aa =
        Algorithm.build
            []
    , ab =
        Algorithm.build
            []
    , e =
        Algorithm.build
            []
    , f =
        Algorithm.build
            []
    , ja =
        Algorithm.build
            []
    , jb =
        Algorithm.build
            []
    , ra =
        Algorithm.build
            []
    , rb =
        Algorithm.build
            []
    , t =
        Algorithm.build
            []
    , y =
        Algorithm.build
            []
    , v =
        Algorithm.build
            []
    , na =
        Algorithm.build
            []
    , nb =
        Algorithm.build
            []
    , ga =
        Algorithm.build
            []
    , gb =
        Algorithm.build
            []
    , gc =
        Algorithm.build
            []
    , gd =
        Algorithm.build
            []
    }
