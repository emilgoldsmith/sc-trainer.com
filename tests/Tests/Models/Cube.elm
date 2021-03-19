module Tests.Models.Cube exposing (suite, testHelperTests)

import Expect
import Fuzz
import Models.Algorithm as Algorithm
import Models.Cube as Cube exposing (Color(..), Cube)
import Monads.ListM as ListM
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
            , fuzz2 commutativePairsFuzzer cubeFuzzer "parallel turns are commutative" <|
                \( turn1, turn2 ) cube ->
                    Cube.applyAlgorithm (Algorithm.build [ turn1, turn2 ]) cube
                        |> Expect.equal (Cube.applyAlgorithm (Algorithm.build [ turn2, turn1 ]) cube)
            , fuzz2 nonCommutativePairsFuzzer cubeFuzzer "non parallel turns are not commutative" <|
                \( turn1, turn2 ) cube ->
                    Cube.applyAlgorithm (Algorithm.build [ turn1, turn2 ]) cube
                        |> Expect.notEqual (Cube.applyAlgorithm (Algorithm.build [ turn2, turn1 ]) cube)
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


testHelperTests : Test
testHelperTests =
    describe "test helper tests"
        [ describe "parallel turns"
            [ test "up or down group is disjoint with front or back group" <|
                \_ ->
                    List.filter (\uOrD -> List.member uOrD frontOrBackParallelGroup) upOrDownParallelGroup
                        |> Expect.equal []
            , test "up or down group is disjoint with left or right group" <|
                \_ ->
                    List.filter (\uOrD -> List.member uOrD leftOrRightParallelGroup) upOrDownParallelGroup
                        |> Expect.equal []
            , test "front or back group is disjoint with left or right group" <|
                \_ ->
                    List.filter (\fOrB -> List.member fOrB leftOrRightParallelGroup) frontOrBackParallelGroup
                        |> Expect.equal []
            , test "three parallel groups have same length as all turns" <|
                \_ ->
                    [ upOrDownParallelGroup, frontOrBackParallelGroup, leftOrRightParallelGroup ]
                        |> List.map List.length
                        |> List.sum
                        |> Expect.equal (List.length Algorithm.allTurns)
            , test "parallelPairs and nonParallelPairs are disjoint" <|
                \_ ->
                    List.filter (\parallel -> List.member parallel nonCommutativePairs) commutativePairs
                        |> Expect.equal []
            , test "parallelPairs + nonParallelPairs have same length as amount of pairs of turns" <|
                \_ ->
                    let
                        numTurns =
                            List.length Algorithm.allTurns

                        -- Every turn is matched with all turns that haven't been matched with yet
                        -- to avoid (a, b) (b, a) duplicates. This gives us an arithmetic sequence
                        -- of numTurns + (numTurns - 1) + ... + 1 which can be calculated with
                        -- the below formula, where we can safely assume numTurns is even (and
                        -- otherwise the test should fail anyway!)
                        numUniquePairs =
                            (numTurns + 1) * (numTurns // 2)
                    in
                    [ commutativePairs, nonCommutativePairs ]
                        |> List.map List.length
                        |> List.sum
                        |> Expect.equal numUniquePairs
            ]
        ]


commutativePairsFuzzer : Fuzz.Fuzzer ( Algorithm.Turn, Algorithm.Turn )
commutativePairsFuzzer =
    Fuzz.oneOf <| List.map Fuzz.constant commutativePairs


nonCommutativePairsFuzzer : Fuzz.Fuzzer ( Algorithm.Turn, Algorithm.Turn )
nonCommutativePairsFuzzer =
    Fuzz.oneOf <| List.map Fuzz.constant nonCommutativePairs


nonCommutativePairs : List ( Algorithm.Turn, Algorithm.Turn )
nonCommutativePairs =
    uniqueCartesianProductWithSelf Algorithm.allTurns
        |> List.filter (\anyPair -> not <| List.member anyPair commutativePairs)


commutativePairs : List ( Algorithm.Turn, Algorithm.Turn )
commutativePairs =
    List.concatMap uniqueCartesianProductWithSelf [ upOrDownParallelGroup, frontOrBackParallelGroup, leftOrRightParallelGroup ] ++ nonParallelCommutativePairs


uniqueCartesianProductWithSelf : List Algorithm.Turn -> List ( Algorithm.Turn, Algorithm.Turn )
uniqueCartesianProductWithSelf group =
    ListM.return Tuple.pair
        |> ListM.applicative (ListM.fromList group)
        |> ListM.applicative (ListM.fromList group)
        |> ListM.toList
        |> List.map
            (\( a, b ) ->
                if compareTurns a b == GT then
                    ( b, a )

                else
                    ( a, b )
            )
        |> List.sortWith
            (\( aa, ab ) ( ba, bb ) ->
                if compareTurns aa ba /= EQ then
                    compareTurns aa ba

                else
                    compareTurns ab bb
            )
        |> List.foldl
            (\next cur ->
                case cur of
                    [] ->
                        [ next ]

                    (x :: _) as all ->
                        if next == x then
                            all

                        else
                            next :: all
            )
            []


{-| There are some moves that are commutative despite not being parallel to each other
-}
nonParallelCommutativePairs : List ( Algorithm.Turn, Algorithm.Turn )
nonParallelCommutativePairs =
    let
        sliceTurnables =
            List.filter isSlice Algorithm.allTurnables

        allDoubleSliceTurns =
            ListM.return Algorithm.Turn
                |> ListM.applicative (ListM.fromList sliceTurnables)
                |> ListM.applicative (ListM.fromList [ Algorithm.Halfway ])
                |> ListM.applicative (ListM.fromList Algorithm.allTurnDirections)
                |> ListM.toList
    in
    uniqueCartesianProductWithSelf allDoubleSliceTurns
        -- Remove the parallel ones aka the ones that have equal turnables
        |> List.filter (\( Algorithm.Turn a _ _, Algorithm.Turn b _ _ ) -> a /= b)


isSlice : Algorithm.Turnable -> Bool
isSlice turnable =
    List.member turnable [ Algorithm.M, Algorithm.S, Algorithm.E ]


compareTurns : Algorithm.Turn -> Algorithm.Turn -> Order
compareTurns (Algorithm.Turn turnableA lengthA directionA) (Algorithm.Turn turnableB lengthB directionB) =
    let
        turnable =
            compareTurnables turnableA turnableB

        length =
            compareTurnLengths lengthA lengthB

        direction =
            compareTurnDirections directionA directionB
    in
    if turnable /= EQ then
        turnable

    else if length /= EQ then
        length

    else
        direction


compareTurnables : Algorithm.Turnable -> Algorithm.Turnable -> Order
compareTurnables =
    compareByListOrder Algorithm.allTurnables


compareTurnLengths : Algorithm.TurnLength -> Algorithm.TurnLength -> Order
compareTurnLengths =
    compareByListOrder Algorithm.allTurnLengths


compareTurnDirections : Algorithm.TurnDirection -> Algorithm.TurnDirection -> Order
compareTurnDirections =
    compareByListOrder Algorithm.allTurnDirections


compareByListOrder : List a -> a -> a -> Order
compareByListOrder order a b =
    let
        orderedElements =
            List.filter (\x -> x == a || x == b) order
    in
    if a == b then
        EQ

    else
        List.head orderedElements
            -- Unsafe function in the sense that we assume there are the two elements
            -- we expect, so weird stuff could happen with bad inputs
            |> Maybe.map
                (\x ->
                    if x == a then
                        LT

                    else
                        GT
                )
            |> Maybe.withDefault EQ


type ParallelGroup
    = UpOrDownGroup
    | FrontOrBackGroup
    | LeftOrRightGroup


upOrDownParallelGroup : List Algorithm.Turn
upOrDownParallelGroup =
    List.partition (getParallelGroup >> isUpOrDownGroup) Algorithm.allTurns |> Tuple.first


frontOrBackParallelGroup : List Algorithm.Turn
frontOrBackParallelGroup =
    List.partition (getParallelGroup >> isFrontOrBackGroup) Algorithm.allTurns |> Tuple.first


leftOrRightParallelGroup : List Algorithm.Turn
leftOrRightParallelGroup =
    List.partition (getParallelGroup >> isLeftOrRightGroup) Algorithm.allTurns |> Tuple.first


getParallelGroup : Algorithm.Turn -> ParallelGroup
getParallelGroup turn =
    case turn of
        Algorithm.Turn Algorithm.U _ _ ->
            UpOrDownGroup

        Algorithm.Turn Algorithm.D _ _ ->
            UpOrDownGroup

        Algorithm.Turn Algorithm.E _ _ ->
            UpOrDownGroup

        Algorithm.Turn Algorithm.F _ _ ->
            FrontOrBackGroup

        Algorithm.Turn Algorithm.B _ _ ->
            FrontOrBackGroup

        Algorithm.Turn Algorithm.S _ _ ->
            FrontOrBackGroup

        Algorithm.Turn Algorithm.L _ _ ->
            LeftOrRightGroup

        Algorithm.Turn Algorithm.R _ _ ->
            LeftOrRightGroup

        Algorithm.Turn Algorithm.M _ _ ->
            LeftOrRightGroup


isUpOrDownGroup : ParallelGroup -> Bool
isUpOrDownGroup parallelGroup =
    case parallelGroup of
        UpOrDownGroup ->
            True

        FrontOrBackGroup ->
            False

        LeftOrRightGroup ->
            False


isFrontOrBackGroup : ParallelGroup -> Bool
isFrontOrBackGroup parallelGroup =
    case parallelGroup of
        UpOrDownGroup ->
            False

        FrontOrBackGroup ->
            True

        LeftOrRightGroup ->
            False


isLeftOrRightGroup : ParallelGroup -> Bool
isLeftOrRightGroup parallelGroup =
    case parallelGroup of
        UpOrDownGroup ->
            False

        FrontOrBackGroup ->
            False

        LeftOrRightGroup ->
            True


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
