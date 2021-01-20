module Models.Cube exposing (Color(..), Cube, CubieRendering, Rendering, applyAlgorithm, render, solved)

{-| The Cube Model Module
-}

import Array exposing (Array)
import Models.Algorithm as Algorithm exposing (Algorithm, TurnDirection(..))
import Set exposing (Set)
import Utils.Permutation as Permutation exposing (Permutation)


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
    Cube
        { ufr = ( UFR, NotTwisted )
        , ufl = ( UFL, NotTwisted )
        , ubl = ( UBL, NotTwisted )
        , ubr = ( UBR, NotTwisted )
        }
        { uf = ( UF, NotFlipped )
        , ur = ( UR, NotFlipped )
        , ub = ( UB, NotFlipped )
        , ul = ( UL, NotFlipped )
        }



-- CUBE MODEL


type Cube
    = Cube CornerPositions EdgePositions



-- CORNER MODEL


type alias CornerPositions =
    { ufr : OrientedCorner
    , ufl : OrientedCorner
    , ubl : OrientedCorner
    , ubr : OrientedCorner
    }


type alias OrientedCorner =
    ( Corner, CornerOrientation )


type Corner
    = UFR
    | UFL
    | UBR
    | UBL


type CornerOrientation
    = NotTwisted
    | TwistedClockwise
    | TwistedCounterClockwise



-- EDGE MODEL


type alias EdgePositions =
    { uf : OrientedEdge
    , ur : OrientedEdge
    , ub : OrientedEdge
    , ul : OrientedEdge
    }


type alias OrientedEdge =
    ( Edge, EdgeOrientation )


type Edge
    = UF
    | UB
    | UR
    | UL


type EdgeOrientation
    = NotFlipped
    | Flipped



-- MOVE APPLICATION


type alias TurnPermutation =
    ( Permutation CornerLocation, Permutation EdgeLocation )


{-| Apply an algorithm to a cube, see example for [`solved`](Model.Cube#solved)
-}
applyAlgorithm : Algorithm -> Cube -> Cube
applyAlgorithm alg cube =
    List.foldl applyTurn cube (Algorithm.extractInternals alg)


applyTurn : Algorithm.Turn -> Cube -> Cube
applyTurn turn =
    applyOrientationChanges turn >> applyPermutationChanges turn


applyOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyOrientationChanges turn =
    applyEdgeOrientationChanges turn >> applyCornerOrientationChanges turn


applyEdgeOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyEdgeOrientationChanges (Algorithm.Turn turnable _ _) cube =
    case turnable of
        _ ->
            cube


flipEdge : OrientedEdge -> OrientedEdge
flipEdge ( edge, orientation ) =
    case orientation of
        NotFlipped ->
            ( edge, Flipped )

        Flipped ->
            ( edge, NotFlipped )


applyCornerOrientationChanges : Algorithm.Turn -> Cube -> Cube
applyCornerOrientationChanges (Algorithm.Turn turnable _ _) cube =
    case turnable of
        _ ->
            cube


applyPermutationChanges : Algorithm.Turn -> Cube -> Cube
applyPermutationChanges =
    getPermutation >> applyTurnPermutation


getPermutation : Algorithm.Turn -> TurnPermutation
getPermutation turn =
    let
        clockwiseQuarterPermutation =
            getClockwiseQuarterTurnPermutation turn
    in
    Tuple.mapBoth (clockwiseQuarterToFullTurnPermutation turn) (clockwiseQuarterToFullTurnPermutation turn) clockwiseQuarterPermutation


clockwiseQuarterToFullTurnPermutation : Algorithm.Turn -> Permutation a -> Permutation a
clockwiseQuarterToFullTurnPermutation (Algorithm.Turn _ length direction) permutation =
    let
        transformPermutationLength =
            case length of
                Algorithm.OneQuarter ->
                    identity

                Algorithm.DoubleTurn ->
                    Permutation.toThePowerOf 2

                Algorithm.ThreeQuarters ->
                    Permutation.reverse

        transformDirection =
            case direction of
                Clockwise ->
                    identity

                CounterClockwise ->
                    Permutation.reverse
    in
    permutation
        |> transformPermutationLength
        |> transformDirection


getClockwiseQuarterTurnPermutation : Algorithm.Turn -> TurnPermutation
getClockwiseQuarterTurnPermutation (Algorithm.Turn turnable _ _) =
    case turnable of
        Algorithm.U ->
            ( Permutation.build [ [ UFRLoc, UFLLoc, UBLLoc, UBRLoc ] ], Permutation.build [ [ UFLoc, ULLoc, UBLoc, URLoc ] ] )


applyTurnPermutation : TurnPermutation -> Cube -> Cube
applyTurnPermutation ( cornerPermutation, edgePermutation ) =
    Permutation.apply cornerAccessors cornerPermutation >> Permutation.apply edgeAccessors edgePermutation


cornerAccessors : Permutation.Accessor CornerLocation Cube OrientedCorner
cornerAccessors =
    Permutation.buildAccessor getCorner setCorner


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
    in
    Cube newCorners edges


edgeAccessors : Permutation.Accessor EdgeLocation Cube OrientedEdge
edgeAccessors =
    Permutation.buildAccessor getEdge setEdge


getEdge : EdgeLocation -> Cube -> OrientedEdge
getEdge location (Cube _ edges) =
    case location of
        UFLoc ->
            edges.uf

        URLoc ->
            edges.ur

        UBLoc ->
            edges.ub

        ULLoc ->
            edges.ul


setEdge : EdgeLocation -> OrientedEdge -> Cube -> Cube
setEdge location edgeToSet (Cube corners edges) =
    let
        newEdges =
            case location of
                UFLoc ->
                    { edges | uf = edgeToSet }

                URLoc ->
                    { edges | ur = edgeToSet }

                UBLoc ->
                    { edges | ub = edgeToSet }

                ULLoc ->
                    { edges | ul = edgeToSet }
    in
    Cube corners newEdges



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


{-| Helper for easier construction of rendered cubies. This allows you to only specify
the stickers that are actually colored and the rest will automatically be designated
as PlasticColor

    ufr =
        { plainCubie | u = UpColor, f = FrontColor, r = RightColor }

-}
plainCubie : CubieRendering
plainCubie =
    { u = PlasticColor, f = PlasticColor, r = PlasticColor, d = PlasticColor, l = PlasticColor, b = PlasticColor }


type Color
    = UpColor
    | DownColor
    | FrontColor
    | BackColor
    | LeftColor
    | RightColor
    | PlasticColor


render : Cube -> Rendering
render (Cube corners edges) =
    { -- U Corners
      ufr = renderCorner UFRLoc corners.ufr
    , ufl = renderCorner UFLLoc corners.ufl
    , ubl = renderCorner UBLLoc corners.ubl
    , ubr = renderCorner UBRLoc corners.ubr

    -- D Corners
    , dbr = { u = PlasticColor, f = PlasticColor, l = PlasticColor, r = RightColor, d = DownColor, b = BackColor }
    , dbl = { u = PlasticColor, f = PlasticColor, l = LeftColor, r = PlasticColor, d = DownColor, b = BackColor }
    , dfl = { u = PlasticColor, f = FrontColor, l = LeftColor, r = PlasticColor, d = DownColor, b = PlasticColor }
    , dfr = { u = PlasticColor, f = FrontColor, l = PlasticColor, r = RightColor, d = DownColor, b = PlasticColor }

    -- M Edges
    , uf = renderEdge UFLoc edges.uf
    , ub = renderEdge UBLoc edges.ub
    , db = { u = PlasticColor, f = PlasticColor, r = PlasticColor, d = DownColor, l = PlasticColor, b = BackColor }
    , df = { u = PlasticColor, f = FrontColor, r = PlasticColor, d = DownColor, l = PlasticColor, b = PlasticColor }

    -- S Edges
    , dl = { u = PlasticColor, f = PlasticColor, r = PlasticColor, d = DownColor, l = LeftColor, b = PlasticColor }
    , dr = { u = PlasticColor, f = PlasticColor, r = RightColor, d = DownColor, l = PlasticColor, b = PlasticColor }
    , ur = renderEdge URLoc edges.ur
    , ul = renderEdge ULLoc edges.ul

    -- E Edges
    , fl = { u = PlasticColor, f = FrontColor, r = PlasticColor, d = PlasticColor, l = LeftColor, b = PlasticColor }
    , fr = { u = PlasticColor, f = FrontColor, r = RightColor, d = PlasticColor, l = PlasticColor, b = PlasticColor }
    , br = { u = PlasticColor, f = PlasticColor, r = RightColor, d = PlasticColor, l = PlasticColor, b = BackColor }
    , bl = { u = PlasticColor, f = PlasticColor, r = PlasticColor, d = PlasticColor, l = LeftColor, b = BackColor }
    }



-- CORNER RENDERING


type CornerLocation
    = UFRLoc
    | UFLLoc
    | UBRLoc
    | UBLLoc


{-| We have chosen the U/D layers for our reference stickers for corners. This means that
we consider a corner oriented correctly if its U or D sticker is on the U or D layer,
and respectively it is oriented clockwise / counterclockwise if the U / D sticker for
the corner is a counter / counterclockwise turn away from the U / D
-}
renderCorner : CornerLocation -> OrientedCorner -> CubieRendering
renderCorner location orientedCorner =
    case location of
        UFRLoc ->
            { plainCubie | u = getCornerReferenceSticker orientedCorner, f = getCounterClockwiseSticker orientedCorner, r = getClockwiseSticker orientedCorner }

        UFLLoc ->
            { plainCubie | u = getCornerReferenceSticker orientedCorner, f = getClockwiseSticker orientedCorner, l = getCounterClockwiseSticker orientedCorner }

        UBLLoc ->
            { plainCubie | u = getCornerReferenceSticker orientedCorner, b = getCounterClockwiseSticker orientedCorner, l = getClockwiseSticker orientedCorner }

        UBRLoc ->
            { plainCubie | u = getCornerReferenceSticker orientedCorner, b = getClockwiseSticker orientedCorner, r = getCounterClockwiseSticker orientedCorner }


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
getLocationAgnosticCornerRendering orientedCorner =
    let
        notTwistedRendering =
            case Tuple.first orientedCorner of
                UFL ->
                    { referenceSticker = UpColor, clockwiseSticker = FrontColor, counterClockwiseSticker = LeftColor }

                UFR ->
                    { referenceSticker = UpColor, clockwiseSticker = RightColor, counterClockwiseSticker = FrontColor }

                UBR ->
                    { referenceSticker = UpColor, clockwiseSticker = BackColor, counterClockwiseSticker = RightColor }

                UBL ->
                    { referenceSticker = UpColor, clockwiseSticker = LeftColor, counterClockwiseSticker = BackColor }
    in
    applyTwist (Tuple.second orientedCorner) notTwistedRendering


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


type EdgeLocation
    = UFLoc
    | UBLoc
    | URLoc
    | ULLoc


{-| We have chosen the U/D layers for our reference stickers for edges that have a
U or D sticker. For the last 4 edges we use the F/B layers. This works the same as
corners. If the U/D F/B sticker is on the U/D F/B layer we consider the edge
oriented correctly, otherwise we consider it flipped.
-}
renderEdge : EdgeLocation -> OrientedEdge -> CubieRendering
renderEdge location orientedEdge =
    case location of
        UFLoc ->
            { plainCubie | u = getEdgeReferenceSticker orientedEdge, f = getOtherSticker orientedEdge }

        URLoc ->
            { plainCubie | u = getEdgeReferenceSticker orientedEdge, r = getOtherSticker orientedEdge }

        UBLoc ->
            { plainCubie | u = getEdgeReferenceSticker orientedEdge, b = getOtherSticker orientedEdge }

        ULLoc ->
            { plainCubie | u = getEdgeReferenceSticker orientedEdge, l = getOtherSticker orientedEdge }


type alias LocationAgnosticEdgeRendering =
    { referenceSticker : Color, otherSticker : Color }


getEdgeReferenceSticker : OrientedEdge -> Color
getEdgeReferenceSticker =
    getLocationAgnosticEdgeRendering >> .referenceSticker


getOtherSticker : OrientedEdge -> Color
getOtherSticker =
    getLocationAgnosticEdgeRendering >> .otherSticker


getLocationAgnosticEdgeRendering : OrientedEdge -> LocationAgnosticEdgeRendering
getLocationAgnosticEdgeRendering orientedEdge =
    let
        notFlippedRendering =
            case Tuple.first orientedEdge of
                UF ->
                    { referenceSticker = UpColor, otherSticker = FrontColor }

                UR ->
                    { referenceSticker = UpColor, otherSticker = RightColor }

                UB ->
                    { referenceSticker = UpColor, otherSticker = BackColor }

                UL ->
                    { referenceSticker = UpColor, otherSticker = LeftColor }
    in
    applyFlip (Tuple.second orientedEdge) notFlippedRendering


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
