module Models.Cube exposing (Color(..), CubieRendering, Rendering, applyAlgorithm, render, solved)

{-| The Cube Model Module
-}

import Models.Algorithm as Algorithm exposing (Algorithm)


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
    ( { ufr = ( UFR, NotTwisted )
      , ufl = ( UFL, NotTwisted )
      , ubl = ( UBL, NotTwisted )
      , ubr = ( UBR, NotTwisted )
      }
    , { uf = ( UF, NotFlipped )
      , ur = ( UR, NotFlipped )
      , ub = ( UB, NotFlipped )
      , ul = ( UL, NotFlipped )
      }
    )



-- CUBE MODEL


type alias Cube =
    ( CornerPositions, EdgePositions )



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


{-| Apply an algorithm to a cube, see example for [`solved`](Model.Cube#solved)
-}
applyAlgorithm : Algorithm -> Cube -> Cube
applyAlgorithm alg cube =
    List.foldl applyTurn cube (Algorithm.extractInternals alg)


applyTurn : Algorithm.Turn -> Cube -> Cube
applyTurn (Algorithm.Turn layer length direction) cube =
    case layer of
        Algorithm.U ->
            cube



-- type alias CornerFaceClockwiseOrder =
--     { first : Corner, second : Corner, third : Corner, fourth : Corner }
-- type alias EdgeFaceClockwiseOrder =
--     { first : Edge, second : Edge, third : Edge, fourth : Edge }
-- applyQuarterTurn : List Corner -> List Edge -> MoveDirection -> Cube -> Cube
-- applyQuarterTurn clockwiseCorners clockwiseEdge direction cube = case
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
render ( corners, edges ) =
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
