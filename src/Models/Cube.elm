module Models.Cube exposing (Color(..), Cube, CubieRendering, Rendering, applyAlgorithm, render, solved)

{-| The Cube Model Module
-}

import Models.Algorithm as Algorithm exposing (Algorithm)
import Utils.Permutation as Permutation exposing (Permutation)



-- CUBE MODEL


type Cube
    = Cube CornerPositions EdgePositions



-- CORNER MODEL


type alias CornerPositions =
    { ufr : OrientedCorner
    , ufl : OrientedCorner
    , ubl : OrientedCorner
    , ubr : OrientedCorner
    , dfr : OrientedCorner
    , dfl : OrientedCorner
    , dbl : OrientedCorner
    , dbr : OrientedCorner
    }


type CornerLocation
    = UFRLoc
    | UFLLoc
    | UBRLoc
    | UBLLoc
    | DFRLoc
    | DFLLoc
    | DBRLoc
    | DBLLoc


getCorner : CornerLocation -> Cube -> OrientedCorner
getCorner location (Cube corners _) =
    case location of
        UFRLoc ->
            corners.ufr

        UFLLoc ->
            corners.ufl

        UBRLoc ->
            corners.ubr

        UBLLoc ->
            corners.ubl

        DBRLoc ->
            corners.dbr

        DFLLoc ->
            corners.dfl

        DFRLoc ->
            corners.dfr

        DBLLoc ->
            corners.dbl


setCorner : CornerLocation -> OrientedCorner -> Cube -> Cube
setCorner location cornerToSet (Cube corners edges) =
    let
        newCorners =
            case location of
                UFRLoc ->
                    { corners | ufr = cornerToSet }

                UFLLoc ->
                    { corners | ufl = cornerToSet }

                UBRLoc ->
                    { corners | ubr = cornerToSet }

                UBLLoc ->
                    { corners | ubl = cornerToSet }

                DFRLoc ->
                    { corners | dfr = cornerToSet }

                DFLLoc ->
                    { corners | dfl = cornerToSet }

                DBRLoc ->
                    { corners | dbr = cornerToSet }

                DBLLoc ->
                    { corners | dbl = cornerToSet }
    in
    Cube newCorners edges


type OrientedCorner
    = OrientedCorner Corner CornerOrientation


type Corner
    = -- U Corners
      UFR
    | UFL
    | UBR
    | UBL
      -- D Corners
    | DFR
    | DFL
    | DBR
    | DBL


type CornerOrientation
    = NotTwisted
    | TwistedClockwise
    | TwistedCounterClockwise



-- EDGE MODEL


type alias EdgePositions =
    { -- M Edges
      uf : OrientedEdge
    , ub : OrientedEdge
    , df : OrientedEdge
    , db : OrientedEdge

    -- S Edges
    , ur : OrientedEdge
    , ul : OrientedEdge
    , dr : OrientedEdge
    , dl : OrientedEdge

    -- E Edges
    , fr : OrientedEdge
    , fl : OrientedEdge
    , br : OrientedEdge
    , bl : OrientedEdge
    }


type EdgeLocation
    = -- M Edges
      UFLoc
    | UBLoc
    | DFLoc
    | DBLoc
      -- S Edges
    | URLoc
    | ULLoc
    | DRLoc
    | DLLoc
      -- E Edges
    | FRLoc
    | FLLoc
    | BRLoc
    | BLLoc


getEdge : EdgeLocation -> Cube -> OrientedEdge
getEdge location (Cube _ edges) =
    case location of
        -- M Edges
        UFLoc ->
            edges.uf

        UBLoc ->
            edges.ub

        DFLoc ->
            edges.df

        DBLoc ->
            edges.db

        -- S Edges
        URLoc ->
            edges.ur

        ULLoc ->
            edges.ul

        DRLoc ->
            edges.dr

        DLLoc ->
            edges.dl

        -- E Edges
        FRLoc ->
            edges.fr

        FLLoc ->
            edges.fl

        BRLoc ->
            edges.br

        BLLoc ->
            edges.bl


setEdge : EdgeLocation -> OrientedEdge -> Cube -> Cube
setEdge location edgeToSet (Cube corners edges) =
    let
        newEdges =
            case location of
                -- M Edges
                UFLoc ->
                    { edges | uf = edgeToSet }

                UBLoc ->
                    { edges | ub = edgeToSet }

                DFLoc ->
                    { edges | df = edgeToSet }

                DBLoc ->
                    { edges | db = edgeToSet }

                -- S Edges
                URLoc ->
                    { edges | ur = edgeToSet }

                ULLoc ->
                    { edges | ul = edgeToSet }

                DRLoc ->
                    { edges | dr = edgeToSet }

                DLLoc ->
                    { edges | dl = edgeToSet }

                -- E Edges
                FRLoc ->
                    { edges | fr = edgeToSet }

                FLLoc ->
                    { edges | fl = edgeToSet }

                BRLoc ->
                    { edges | br = edgeToSet }

                BLLoc ->
                    { edges | bl = edgeToSet }
    in
    Cube corners newEdges


type OrientedEdge
    = OrientedEdge Edge EdgeOrientation


type Edge
    = -- M Edges
      UF
    | UB
    | DF
    | DB
      -- S Edges
    | UR
    | UL
    | DR
    | DL
      -- E Edges
    | FR
    | FL
    | BR
    | BL


type EdgeOrientation
    = NotFlipped
    | Flipped



-- CUBE CONSTRUCTORS


{-| A solved cube. This is your entry point into this module, if you need a cube at
a specific state you take this as a starting point and apply the algorithm on it to
get to that state like this:

    import Model.Cube as Cube
    import Model.Algorithm as Algorithm

    -- This would generate a cube with one of the big fish OLLs
    Cube.solved |> Cube.applyAlgorithm (Algorithm.fromString "RUR'U'R'FRF'")

-}
solved : Cube
solved =
    let
        solvedCorner location =
            OrientedCorner location NotTwisted

        solvedEdge location =
            OrientedEdge location NotFlipped
    in
    Cube
        { -- U Corners
          ufr = solvedCorner UFR
        , ufl = solvedCorner UFL
        , ubl = solvedCorner UBL
        , ubr = solvedCorner UBR

        -- D Corners
        , dfr = solvedCorner DFR
        , dfl = solvedCorner DFL
        , dbl = solvedCorner DBL
        , dbr = solvedCorner DBR
        }
        { -- M Edges
          uf = solvedEdge UF
        , ub = solvedEdge UB
        , df = solvedEdge DF
        , db = solvedEdge DB

        -- S Edges
        , ur = solvedEdge UR
        , ul = solvedEdge UL
        , dr = solvedEdge DR
        , dl = solvedEdge DL

        -- E Edges
        , fr = solvedEdge FR
        , fl = solvedEdge FL
        , br = solvedEdge BR
        , bl = solvedEdge BL
        }



-- MOVE APPLICATION


{-| Apply an algorithm to a cube, see example for [`solved`](Model.Cube#solved)
-}
applyAlgorithm : Algorithm -> Cube -> Cube
applyAlgorithm alg cube =
    List.foldl applyTurn cube (Algorithm.extractInternals alg)


applyTurn : Algorithm.Turn -> Cube -> Cube
applyTurn turn =
    applyOrientationChanges turn >> applyPermutationChanges turn



-- Orientation Changes


applyOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyOrientationChanges turn =
    applyEdgeOrientationChanges turn >> applyCornerOrientationChanges turn


applyEdgeOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyEdgeOrientationChanges (Algorithm.Turn turnable _ _) cube =
    case turnable of
        _ ->
            cube


applyCornerOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyCornerOrientationChanges (Algorithm.Turn turnable turnLength _) cube =
    case turnLength of
        -- A double turn always reverses the orientation change again
        Algorithm.Halfway ->
            cube

        -- Three quarter turns act the same as a quarter turn
        _ ->
            case turnable of
                Algorithm.L ->
                    cube
                        |> applyClockwiseTwist UBLLoc
                        |> applyClockwiseTwist DFLLoc
                        |> applyCounterClockwiseTwist UFLLoc
                        |> applyCounterClockwiseTwist DBLLoc

                Algorithm.R ->
                    cube
                        |> applyClockwiseTwist UFRLoc
                        |> applyClockwiseTwist DBRLoc
                        |> applyCounterClockwiseTwist UBRLoc
                        |> applyCounterClockwiseTwist DFRLoc

                _ ->
                    cube


applyClockwiseTwist : CornerLocation -> Cube -> Cube
applyClockwiseTwist location cube =
    let
        (OrientedCorner corner orientation) =
            getCorner location cube

        newOrientation =
            case orientation of
                NotTwisted ->
                    TwistedClockwise

                TwistedClockwise ->
                    TwistedCounterClockwise

                TwistedCounterClockwise ->
                    NotTwisted
    in
    setCorner location (OrientedCorner corner newOrientation) cube


applyCounterClockwiseTwist : CornerLocation -> Cube -> Cube
applyCounterClockwiseTwist location cube =
    let
        (OrientedCorner corner orientation) =
            getCorner location cube

        newOrientation =
            case orientation of
                NotTwisted ->
                    TwistedCounterClockwise

                TwistedCounterClockwise ->
                    TwistedClockwise

                TwistedClockwise ->
                    NotTwisted
    in
    setCorner location (OrientedCorner corner newOrientation) cube



-- Permutation Changes


type TurnPermutation
    = TurnPermutation (Permutation CornerLocation) (Permutation EdgeLocation)


applyPermutationChanges : Algorithm.Turn -> Cube -> Cube
applyPermutationChanges =
    getPermutation >> applyTurnPermutation



-- Construct the permutation definition for the turn


getPermutation : Algorithm.Turn -> TurnPermutation
getPermutation turn =
    let
        (ClockwiseQuarterTurnPermutation cornerPermutation edgePermutation) =
            getClockwiseQuarterPermutation turn
    in
    TurnPermutation (toFullPermutation turn cornerPermutation) (toFullPermutation turn edgePermutation)



-- First get the clockwise quarter turn permutation


type ClockwiseQuarterPermutation a
    = ClockwiseQuarterPermutation (Permutation a)


type ClockwiseQuarterTurnPermutation
    = ClockwiseQuarterTurnPermutation (ClockwiseQuarterPermutation CornerLocation) (ClockwiseQuarterPermutation EdgeLocation)


getClockwiseQuarterPermutation : Algorithm.Turn -> ClockwiseQuarterTurnPermutation
getClockwiseQuarterPermutation (Algorithm.Turn turnable _ _) =
    case turnable of
        Algorithm.U ->
            buildClockwiseQuarterTurnPermutation [ [ UFRLoc, UFLLoc, UBLLoc, UBRLoc ] ] [ [ UFLoc, ULLoc, UBLoc, URLoc ] ]

        Algorithm.D ->
            buildClockwiseQuarterTurnPermutation [ [ DFRLoc, DBRLoc, DBLLoc, DFLLoc ] ] [ [ DFLoc, DRLoc, DBLoc, DLLoc ] ]

        Algorithm.L ->
            buildClockwiseQuarterTurnPermutation [ [ UFLLoc, DFLLoc, DBLLoc, UBLLoc ] ] [ [ ULLoc, FLLoc, DLLoc, BLLoc ] ]

        Algorithm.R ->
            buildClockwiseQuarterTurnPermutation [ [ UFRLoc, UBRLoc, DBRLoc, DFRLoc ] ] [ [ URLoc, BRLoc, DRLoc, FRLoc ] ]


buildClockwiseQuarterTurnPermutation : List (List CornerLocation) -> List (List EdgeLocation) -> ClockwiseQuarterTurnPermutation
buildClockwiseQuarterTurnPermutation cornerCycles edgeCycles =
    ClockwiseQuarterTurnPermutation
        (ClockwiseQuarterPermutation <| Permutation.build cornerCycles)
        (ClockwiseQuarterPermutation <| Permutation.build edgeCycles)



-- Then use the direction and length to convert it to a full turn permutation


toFullPermutation : Algorithm.Turn -> ClockwiseQuarterPermutation a -> Permutation a
toFullPermutation (Algorithm.Turn _ length direction) (ClockwiseQuarterPermutation permutation) =
    permutation
        |> transformLength length
        |> transformDirection direction


transformLength : Algorithm.TurnLength -> Permutation a -> Permutation a
transformLength length =
    case length of
        Algorithm.OneQuarter ->
            identity

        Algorithm.Halfway ->
            Permutation.toThePowerOf 2

        Algorithm.ThreeQuarters ->
            Permutation.reverse


transformDirection : Algorithm.TurnDirection -> Permutation a -> Permutation a
transformDirection direction =
    case direction of
        Algorithm.Clockwise ->
            identity

        Algorithm.CounterClockwise ->
            Permutation.reverse



-- Now that we have defined the permutation correctly we define how to apply the permutation


applyTurnPermutation : TurnPermutation -> Cube -> Cube
applyTurnPermutation (TurnPermutation cornerPermutation edgePermutation) =
    let
        cornerAccessors =
            Permutation.buildAccessor getCorner setCorner

        edgeAccessors =
            Permutation.buildAccessor getEdge setEdge
    in
    Permutation.apply cornerAccessors cornerPermutation >> Permutation.apply edgeAccessors edgePermutation



-- RENDERING


type alias Rendering =
    { -- U Corners
      ufr : CubieRendering
    , ufl : CubieRendering
    , ubl : CubieRendering
    , ubr : CubieRendering

    -- D Corners
    , dfr : CubieRendering
    , dfl : CubieRendering
    , dbl : CubieRendering
    , dbr : CubieRendering

    -- M Edges
    , uf : CubieRendering
    , df : CubieRendering
    , db : CubieRendering
    , ub : CubieRendering

    -- S Edges
    , ur : CubieRendering
    , ul : CubieRendering
    , dl : CubieRendering
    , dr : CubieRendering

    -- E Edges
    , fl : CubieRendering
    , fr : CubieRendering
    , br : CubieRendering
    , bl : CubieRendering
    }


type alias CubieRendering =
    { u : Color
    , d : Color
    , f : Color
    , b : Color
    , l : Color
    , r : Color
    }


type Color
    = UpColor
    | DownColor
    | FrontColor
    | BackColor
    | LeftColor
    | RightColor
    | PlasticColor


{-| Helper for easier construction of rendered cubies. This allows you to only specify
the stickers that are actually colored and the rest will automatically be designated
as PlasticColor

    ufr =
        { plainCubie | u = UpColor, f = FrontColor, r = RightColor }

-}
plainCubie : CubieRendering
plainCubie =
    { u = PlasticColor, f = PlasticColor, r = PlasticColor, d = PlasticColor, l = PlasticColor, b = PlasticColor }


render : Cube -> Rendering
render cube =
    let
        rc =
            renderCorner cube

        re =
            renderEdge cube
    in
    { -- U Corners
      ufr = rc UFRLoc
    , ufl = rc UFLLoc
    , ubl = rc UBLLoc
    , ubr = rc UBRLoc

    -- D Corners
    , dbr = rc DBRLoc
    , dbl = rc DBLLoc
    , dfl = rc DFLLoc
    , dfr = rc DFRLoc

    -- M Edges
    , uf = re UFLoc
    , ub = re UBLoc
    , db = re DBLoc
    , df = re DFLoc

    -- S Edges
    , dl = re DLLoc
    , dr = re DRLoc
    , ur = re URLoc
    , ul = re ULLoc

    -- E Edges
    , fl = re FLLoc
    , fr = re FRLoc
    , br = re BRLoc
    , bl = re BLLoc
    }



-- CORNER RENDERING


{-| We have chosen the U/D layers for our reference stickers for corners. This means that
we consider a corner oriented correctly if its U or D sticker is on the U or D layer,
and respectively it is oriented clockwise / counterclockwise if the U / D sticker for
the corner is a counter / counterclockwise turn away from the U / D
-}
renderCorner : Cube -> CornerLocation -> CubieRendering
renderCorner cube location =
    let
        corner =
            getCorner location cube

        reference =
            getCornerReferenceSticker corner

        counterClockwise =
            getCounterClockwiseSticker corner

        clockwise =
            getClockwiseSticker corner
    in
    case location of
        UFRLoc ->
            { plainCubie | u = reference, f = counterClockwise, r = clockwise }

        UFLLoc ->
            { plainCubie | u = reference, f = clockwise, l = counterClockwise }

        UBLLoc ->
            { plainCubie | u = reference, b = counterClockwise, l = clockwise }

        UBRLoc ->
            { plainCubie | u = reference, b = clockwise, r = counterClockwise }

        DFRLoc ->
            { plainCubie | d = reference, f = clockwise, r = counterClockwise }

        DFLLoc ->
            { plainCubie | d = reference, f = counterClockwise, l = clockwise }

        DBLLoc ->
            { plainCubie | d = reference, b = clockwise, l = counterClockwise }

        DBRLoc ->
            { plainCubie | d = reference, b = counterClockwise, r = clockwise }


type alias LocationAgnosticCornerRendering =
    { referenceSticker : Color, clockwiseSticker : Color, counterClockwiseSticker : Color }


getCornerReferenceSticker : OrientedCorner -> Color
getCornerReferenceSticker =
    getLocationAgnosticCornerRendering >> .referenceSticker


getClockwiseSticker : OrientedCorner -> Color
getClockwiseSticker =
    getLocationAgnosticCornerRendering >> .clockwiseSticker


getCounterClockwiseSticker : OrientedCorner -> Color
getCounterClockwiseSticker =
    getLocationAgnosticCornerRendering >> .counterClockwiseSticker


getLocationAgnosticCornerRendering : OrientedCorner -> LocationAgnosticCornerRendering
getLocationAgnosticCornerRendering (OrientedCorner corner location) =
    let
        notTwistedRendering =
            case corner of
                UFL ->
                    { referenceSticker = UpColor, clockwiseSticker = FrontColor, counterClockwiseSticker = LeftColor }

                UFR ->
                    { referenceSticker = UpColor, clockwiseSticker = RightColor, counterClockwiseSticker = FrontColor }

                UBR ->
                    { referenceSticker = UpColor, clockwiseSticker = BackColor, counterClockwiseSticker = RightColor }

                UBL ->
                    { referenceSticker = UpColor, clockwiseSticker = LeftColor, counterClockwiseSticker = BackColor }

                DFL ->
                    { referenceSticker = DownColor, clockwiseSticker = LeftColor, counterClockwiseSticker = FrontColor }

                DFR ->
                    { referenceSticker = DownColor, clockwiseSticker = FrontColor, counterClockwiseSticker = RightColor }

                DBR ->
                    { referenceSticker = DownColor, clockwiseSticker = RightColor, counterClockwiseSticker = BackColor }

                DBL ->
                    { referenceSticker = DownColor, clockwiseSticker = BackColor, counterClockwiseSticker = LeftColor }
    in
    applyTwist location notTwistedRendering


applyTwist : CornerOrientation -> LocationAgnosticCornerRendering -> LocationAgnosticCornerRendering
applyTwist orientation notTwistedRendering =
    case orientation of
        NotTwisted ->
            notTwistedRendering

        TwistedClockwise ->
            { referenceSticker = notTwistedRendering.counterClockwiseSticker, clockwiseSticker = notTwistedRendering.referenceSticker, counterClockwiseSticker = notTwistedRendering.clockwiseSticker }

        TwistedCounterClockwise ->
            { referenceSticker = notTwistedRendering.clockwiseSticker, clockwiseSticker = notTwistedRendering.counterClockwiseSticker, counterClockwiseSticker = notTwistedRendering.referenceSticker }



-- EDGE RENDERING


{-| We have chosen the U/D layers for our reference stickers for edges that have a
U or D sticker. For the last 4 edges we use the F/B layers. This works the same as
corners. If the U/D F/B sticker is on the U/D F/B layer we consider the edge
oriented correctly, otherwise we consider it flipped.
-}
renderEdge : Cube -> EdgeLocation -> CubieRendering
renderEdge cube location =
    let
        edge =
            getEdge location cube

        reference =
            getEdgeReferenceSticker edge

        other =
            getOtherSticker edge
    in
    case location of
        -- M Edges
        UFLoc ->
            { plainCubie | u = reference, f = other }

        UBLoc ->
            { plainCubie | u = reference, b = other }

        DFLoc ->
            { plainCubie | d = reference, f = other }

        DBLoc ->
            { plainCubie | d = reference, b = other }

        -- S Edges
        URLoc ->
            { plainCubie | u = reference, r = other }

        ULLoc ->
            { plainCubie | u = reference, l = other }

        DRLoc ->
            { plainCubie | d = reference, r = other }

        DLLoc ->
            { plainCubie | d = reference, l = other }

        -- E Edges
        FRLoc ->
            { plainCubie | f = reference, r = other }

        FLLoc ->
            { plainCubie | f = reference, l = other }

        BRLoc ->
            { plainCubie | b = reference, r = other }

        BLLoc ->
            { plainCubie | b = reference, l = other }


type alias LocationAgnosticEdgeRendering =
    { referenceSticker : Color, otherSticker : Color }


getEdgeReferenceSticker : OrientedEdge -> Color
getEdgeReferenceSticker =
    getLocationAgnosticEdgeRendering >> .referenceSticker


getOtherSticker : OrientedEdge -> Color
getOtherSticker =
    getLocationAgnosticEdgeRendering >> .otherSticker


getLocationAgnosticEdgeRendering : OrientedEdge -> LocationAgnosticEdgeRendering
getLocationAgnosticEdgeRendering (OrientedEdge edge location) =
    let
        notFlippedRendering =
            case edge of
                -- M Edges
                UF ->
                    { referenceSticker = UpColor, otherSticker = FrontColor }

                UB ->
                    { referenceSticker = UpColor, otherSticker = BackColor }

                DF ->
                    { referenceSticker = DownColor, otherSticker = FrontColor }

                DB ->
                    { referenceSticker = DownColor, otherSticker = BackColor }

                -- S Edges
                UR ->
                    { referenceSticker = UpColor, otherSticker = RightColor }

                UL ->
                    { referenceSticker = UpColor, otherSticker = LeftColor }

                DR ->
                    { referenceSticker = DownColor, otherSticker = RightColor }

                DL ->
                    { referenceSticker = DownColor, otherSticker = LeftColor }

                -- E Edges
                FR ->
                    { referenceSticker = FrontColor, otherSticker = RightColor }

                FL ->
                    { referenceSticker = FrontColor, otherSticker = LeftColor }

                BR ->
                    { referenceSticker = BackColor, otherSticker = RightColor }

                BL ->
                    { referenceSticker = BackColor, otherSticker = LeftColor }
    in
    applyFlip location notFlippedRendering


applyFlip : EdgeOrientation -> LocationAgnosticEdgeRendering -> LocationAgnosticEdgeRendering
applyFlip orientation spec =
    case orientation of
        NotFlipped ->
            spec

        Flipped ->
            { referenceSticker = spec.otherSticker, otherSticker = spec.referenceSticker }



-- type UpOrDown
--     = Up
--     | Down
-- type FrontOrBack
--     = Front
--     | Back
-- type LeftOrRight
--     = Left
--     | Right
-- Describes how far in the coordinate system a coordinate is from the top front left (UFL) corner
-- type CubieSingleCoordinate
--     = Zero
--     | One
--     | Two
-- type alias CubieCoordinates =
--     { fromTop : CubieSingleCoordinate
--     , fromFront : CubieSingleCoordinate
--     , fromLeft : CubieSingleCoordinate
--     }
