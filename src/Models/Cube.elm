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
    { -- U Corners
      ufr : OrientedCorner
    , ufl : OrientedCorner
    , ubl : OrientedCorner
    , ubr : OrientedCorner

    -- D Corners
    , dfr : OrientedCorner
    , dfl : OrientedCorner
    , dbl : OrientedCorner
    , dbr : OrientedCorner
    }


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



-- LOCATIONS MODEL
-- These pretty much map to the positions above, see helpers at the bottom
-- for the actual mapping


type UOrD
    = U
    | D


type FOrB
    = F
    | B


type LOrR
    = L
    | R


type Face
    = UpOrDown UOrD
    | FrontOrBack FOrB
    | LeftOrRight LOrR


type alias CornerLocation =
    ( UOrD, FOrB, LOrR )


type EdgeLocation
    = M ( UOrD, FOrB )
    | S ( UOrD, LOrR )
    | E ( FOrB, LOrR )



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
                        |> applyClockwiseTwist ( U, B, L )
                        |> applyClockwiseTwist ( D, F, L )
                        |> applyCounterClockwiseTwist ( U, F, L )
                        |> applyCounterClockwiseTwist ( D, B, L )

                Algorithm.R ->
                    cube
                        |> applyClockwiseTwist ( U, F, R )
                        |> applyClockwiseTwist ( D, B, R )
                        |> applyCounterClockwiseTwist ( U, B, R )
                        |> applyCounterClockwiseTwist ( D, F, R )

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
            buildClockwiseQuarterTurnPermutation [ [ ( U, F, R ), ( U, F, L ), ( U, B, L ), ( U, B, R ) ] ] [ [ M ( U, F ), S ( U, L ), M ( U, B ), S ( U, R ) ] ]

        Algorithm.D ->
            buildClockwiseQuarterTurnPermutation [ [ ( D, F, R ), ( D, B, R ), ( D, B, L ), ( D, F, L ) ] ] [ [ M ( D, F ), S ( D, R ), M ( D, B ), S ( D, L ) ] ]

        Algorithm.L ->
            buildClockwiseQuarterTurnPermutation [ [ ( U, F, L ), ( D, F, L ), ( D, B, L ), ( U, B, L ) ] ] [ [ S ( U, L ), E ( F, L ), S ( D, L ), E ( B, L ) ] ]

        Algorithm.R ->
            buildClockwiseQuarterTurnPermutation [ [ ( U, F, R ), ( U, B, R ), ( D, B, R ), ( D, F, R ) ] ] [ [ S ( U, R ), E ( B, R ), S ( D, R ), E ( F, R ) ] ]


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
        corner =
            renderCorner cube

        edge =
            renderEdge cube
    in
    { -- U Corners
      ufr = corner ( U, F, R )
    , ufl = corner ( U, F, L )
    , ubl = corner ( U, B, L )
    , ubr = corner ( U, B, R )

    -- D Corners
    , dbr = corner ( D, B, R )
    , dbl = corner ( D, B, L )
    , dfl = corner ( D, F, L )
    , dfr = corner ( D, F, R )

    -- M Edges
    , uf = edge (M ( U, F ))
    , ub = edge (M ( U, B ))
    , db = edge (M ( D, B ))
    , df = edge (M ( D, F ))

    -- S Edges
    , dl = edge (S ( D, L ))
    , dr = edge (S ( D, R ))
    , ur = edge (S ( U, R ))
    , ul = edge (S ( U, L ))

    -- E Edges
    , fl = edge (E ( F, L ))
    , fr = edge (E ( F, R ))
    , br = edge (E ( B, R ))
    , bl = edge (E ( B, L ))
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
    in
    plainCubie
        |> setColor (getCornerReferenceFace location) (getCornerColorOnReferenceFace corner)
        |> setColor (getClockwiseFace location) (getCornerColorOnClockwiseFace corner)
        |> setColor (getCounterClockwiseFace location) (getCornerColorOnCounterClockwiseFace corner)


getCornerColorOnReferenceFace : OrientedCorner -> Color
getCornerColorOnReferenceFace (OrientedCorner corner orientation) =
    let
        getFace =
            case orientation of
                NotTwisted ->
                    getCornerReferenceFace

                TwistedClockwise ->
                    getCounterClockwiseFace

                TwistedCounterClockwise ->
                    getClockwiseFace
    in
    corner |> getSolvedCornerLocation |> getFace |> getColor


getCornerColorOnClockwiseFace : OrientedCorner -> Color
getCornerColorOnClockwiseFace (OrientedCorner corner orientation) =
    let
        getFace =
            case orientation of
                NotTwisted ->
                    getClockwiseFace

                TwistedClockwise ->
                    getCornerReferenceFace

                TwistedCounterClockwise ->
                    getCounterClockwiseFace
    in
    corner |> getSolvedCornerLocation |> getFace |> getColor


getCornerColorOnCounterClockwiseFace : OrientedCorner -> Color
getCornerColorOnCounterClockwiseFace (OrientedCorner corner orientation) =
    let
        getFace =
            case orientation of
                NotTwisted ->
                    getCounterClockwiseFace

                TwistedClockwise ->
                    getClockwiseFace

                TwistedCounterClockwise ->
                    getCornerReferenceFace
    in
    corner |> getSolvedCornerLocation |> getFace |> getColor


getCornerReferenceFace : CornerLocation -> Face
getCornerReferenceFace ( uOrD, _, _ ) =
    UpOrDown uOrD


getClockwiseFace : CornerLocation -> Face
getClockwiseFace ( uOrD, fOrB, lOrR ) =
    case uOrD of
        U ->
            if isOnFLBRDiagional ( fOrB, lOrR ) then
                FrontOrBack fOrB

            else
                LeftOrRight lOrR

        D ->
            if isOnFLBRDiagional ( fOrB, lOrR ) then
                LeftOrRight lOrR

            else
                FrontOrBack fOrB


getCounterClockwiseFace : CornerLocation -> Face
getCounterClockwiseFace ( uOrD, fOrB, lOrR ) =
    case uOrD of
        U ->
            if isOnFLBRDiagional ( fOrB, lOrR ) then
                LeftOrRight lOrR

            else
                FrontOrBack fOrB

        D ->
            if isOnFLBRDiagional ( fOrB, lOrR ) then
                FrontOrBack fOrB

            else
                LeftOrRight lOrR


isOnFLBRDiagional : ( FOrB, LOrR ) -> Bool
isOnFLBRDiagional tuple =
    case tuple of
        ( F, L ) ->
            True

        ( B, R ) ->
            True

        _ ->
            False



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
    in
    plainCubie
        |> setColor (getEdgeReferenceFace location) (getEdgeColorOnReferenceFace edge)
        |> setColor (getOtherFace location) (getEdgeColorOnOtherFace edge)


getEdgeReferenceFace : EdgeLocation -> Face
getEdgeReferenceFace location =
    case location of
        M ( uOrD, _ ) ->
            UpOrDown uOrD

        S ( uOrD, _ ) ->
            UpOrDown uOrD

        E ( fOrB, _ ) ->
            FrontOrBack fOrB


getOtherFace : EdgeLocation -> Face
getOtherFace location =
    case location of
        M ( _, fOrB ) ->
            FrontOrBack fOrB

        S ( _, lOrR ) ->
            LeftOrRight lOrR

        E ( _, lOrR ) ->
            LeftOrRight lOrR


getEdgeColorOnReferenceFace : OrientedEdge -> Color
getEdgeColorOnReferenceFace (OrientedEdge edge orientation) =
    let
        getFace =
            case orientation of
                NotFlipped ->
                    getEdgeReferenceFace

                Flipped ->
                    getOtherFace
    in
    edge |> getSolvedEdgeLocation |> getFace |> getColor


getEdgeColorOnOtherFace : OrientedEdge -> Color
getEdgeColorOnOtherFace (OrientedEdge edge orientation) =
    let
        getFace =
            case orientation of
                NotFlipped ->
                    getOtherFace

                Flipped ->
                    getEdgeReferenceFace
    in
    edge |> getSolvedEdgeLocation |> getFace |> getColor



-- HELPERS
-- Corner Location Helpers


getCorner : CornerLocation -> Cube -> OrientedCorner
getCorner location (Cube corners _) =
    case location of
        ( U, F, R ) ->
            corners.ufr

        ( U, F, L ) ->
            corners.ufl

        ( U, B, R ) ->
            corners.ubr

        ( U, B, L ) ->
            corners.ubl

        ( D, B, R ) ->
            corners.dbr

        ( D, F, L ) ->
            corners.dfl

        ( D, F, R ) ->
            corners.dfr

        ( D, B, L ) ->
            corners.dbl


setCorner : CornerLocation -> OrientedCorner -> Cube -> Cube
setCorner location cornerToSet (Cube corners edges) =
    let
        newCorners =
            case location of
                ( U, F, R ) ->
                    { corners | ufr = cornerToSet }

                ( U, F, L ) ->
                    { corners | ufl = cornerToSet }

                ( U, B, R ) ->
                    { corners | ubr = cornerToSet }

                ( U, B, L ) ->
                    { corners | ubl = cornerToSet }

                ( D, F, R ) ->
                    { corners | dfr = cornerToSet }

                ( D, F, L ) ->
                    { corners | dfl = cornerToSet }

                ( D, B, R ) ->
                    { corners | dbr = cornerToSet }

                ( D, B, L ) ->
                    { corners | dbl = cornerToSet }
    in
    Cube newCorners edges


getSolvedCornerLocation : Corner -> CornerLocation
getSolvedCornerLocation corner =
    case corner of
        UFL ->
            ( U, F, L )

        UFR ->
            ( U, F, R )

        UBR ->
            ( U, B, R )

        UBL ->
            ( U, B, L )

        DFL ->
            ( D, F, L )

        DFR ->
            ( D, F, R )

        DBR ->
            ( D, B, R )

        DBL ->
            ( D, B, L )



-- Edge Location Helpers


getEdge : EdgeLocation -> Cube -> OrientedEdge
getEdge location (Cube _ edges) =
    case location of
        -- M Edges
        M ( U, F ) ->
            edges.uf

        M ( U, B ) ->
            edges.ub

        M ( D, F ) ->
            edges.df

        M ( D, B ) ->
            edges.db

        -- S Edges
        S ( U, R ) ->
            edges.ur

        S ( U, L ) ->
            edges.ul

        S ( D, R ) ->
            edges.dr

        S ( D, L ) ->
            edges.dl

        -- E Edges
        E ( F, R ) ->
            edges.fr

        E ( F, L ) ->
            edges.fl

        E ( B, R ) ->
            edges.br

        E ( B, L ) ->
            edges.bl


setEdge : EdgeLocation -> OrientedEdge -> Cube -> Cube
setEdge location edgeToSet (Cube corners edges) =
    let
        newEdges =
            case location of
                -- M Edges
                M ( U, F ) ->
                    { edges | uf = edgeToSet }

                M ( U, B ) ->
                    { edges | ub = edgeToSet }

                M ( D, F ) ->
                    { edges | df = edgeToSet }

                M ( D, B ) ->
                    { edges | db = edgeToSet }

                -- S Edges
                S ( U, R ) ->
                    { edges | ur = edgeToSet }

                S ( U, L ) ->
                    { edges | ul = edgeToSet }

                S ( D, R ) ->
                    { edges | dr = edgeToSet }

                S ( D, L ) ->
                    { edges | dl = edgeToSet }

                -- E Edges
                E ( F, R ) ->
                    { edges | fr = edgeToSet }

                E ( F, L ) ->
                    { edges | fl = edgeToSet }

                E ( B, R ) ->
                    { edges | br = edgeToSet }

                E ( B, L ) ->
                    { edges | bl = edgeToSet }
    in
    Cube corners newEdges


getSolvedEdgeLocation : Edge -> EdgeLocation
getSolvedEdgeLocation edge =
    case edge of
        -- M Edges
        UF ->
            M ( U, F )

        UB ->
            M ( U, B )

        DB ->
            M ( D, B )

        DF ->
            M ( D, F )

        -- S Edges
        UL ->
            S ( U, L )

        UR ->
            S ( U, R )

        DR ->
            S ( D, R )

        DL ->
            S ( D, L )

        -- E Edges
        FL ->
            E ( F, L )

        FR ->
            E ( F, R )

        BR ->
            E ( B, R )

        BL ->
            E ( B, L )



-- Rendering Helpers


setColor : Face -> Color -> CubieRendering -> CubieRendering
setColor face color cubie =
    case face of
        UpOrDown U ->
            { cubie | u = color }

        UpOrDown D ->
            { cubie | d = color }

        FrontOrBack F ->
            { cubie | f = color }

        FrontOrBack B ->
            { cubie | b = color }

        LeftOrRight L ->
            { cubie | l = color }

        LeftOrRight R ->
            { cubie | r = color }


getColor : Face -> Color
getColor face =
    case face of
        UpOrDown U ->
            UpColor

        UpOrDown D ->
            DownColor

        FrontOrBack F ->
            FrontColor

        FrontOrBack B ->
            BackColor

        LeftOrRight L ->
            LeftColor

        LeftOrRight R ->
            RightColor
