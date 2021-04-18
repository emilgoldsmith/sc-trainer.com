module Cube exposing (Color(..), Cube, CubieRendering, Rendering, applyAlgorithm, centerLocations, cornerLocations, edgeLocations, faces, flip, render, solved, viewUBLWithLetters, viewUFRNoLetters, viewUFRWithLetters)

{-| The Cube Model Module
-}

import Algorithm
import Element
import Element.Lazy
import Html exposing (..)
import Html.Attributes exposing (..)
import Svg exposing (line, path, svg)
import Svg.Attributes exposing (d, fill, stroke, strokeWidth, viewBox, x1, x2, y1, y2)
import Utils.Css exposing (htmlTestid)
import Utils.Enumerator
import Utils.MappedPermutation as MappedPermutation exposing (MappedPermutation)



-- CUBE MODEL


type Cube
    = Cube CornerPositions EdgePositions CenterPositions



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



-- CENTER MODEL


type alias CenterPositions =
    { u : Center
    , d : Center
    , f : Center
    , b : Center
    , l : Center
    , r : Center
    }


type Center
    = UCenter
    | DCenter
    | FCenter
    | BCenter
    | LCenter
    | RCenter



-- LOCATIONS MODEL
-- These pretty much map to the positions above, see helpers at the bottom
-- for the actual mapping


type alias CornerLocation =
    ( UOrD, FOrB, LOrR )


type EdgeLocation
    = M ( UOrD, FOrB )
    | S ( UOrD, LOrR )
    | E ( FOrB, LOrR )


type CenterLocation
    = CenterLocation Face


type Face
    = UpOrDown UOrD
    | FrontOrBack FOrB
    | LeftOrRight LOrR


uFace : Face
uFace =
    UpOrDown U


dFace : Face
dFace =
    UpOrDown D


fFace : Face
fFace =
    FrontOrBack F


bFace : Face
bFace =
    FrontOrBack B


lFace : Face
lFace =
    LeftOrRight L


rFace : Face
rFace =
    LeftOrRight R


type UOrD
    = U
    | D


type FOrB
    = F
    | B


type LOrR
    = L
    | R



-- CUBE CONSTRUCTORS


{-| A solved cube. This is your entry point into this module, if you need a cube at
a specific state you take this as a starting point and apply the algorithm on it to
get to that state like this:

    import Cube
    import Algorithm

    -- This would generate a cube with one of the big fish OLLs
    -- (though possible parsing errors in fromString would have to be dealt with)
    Cube.solved |> Cube.applyAlgorithm (Algorithm.fromString "RUR'U'R'FRF'")

-}
solved : Cube
solved =
    let
        orientedCorner location =
            OrientedCorner location NotTwisted

        orientedEdge location =
            OrientedEdge location NotFlipped
    in
    Cube
        { -- U Corners
          ufr = orientedCorner UFR
        , ufl = orientedCorner UFL
        , ubl = orientedCorner UBL
        , ubr = orientedCorner UBR

        -- D Corners
        , dfr = orientedCorner DFR
        , dfl = orientedCorner DFL
        , dbl = orientedCorner DBL
        , dbr = orientedCorner DBR
        }
        { -- M Edges
          uf = orientedEdge UF
        , ub = orientedEdge UB
        , df = orientedEdge DF
        , db = orientedEdge DB

        -- S Edges
        , ur = orientedEdge UR
        , ul = orientedEdge UL
        , dr = orientedEdge DR
        , dl = orientedEdge DL

        -- E Edges
        , fr = orientedEdge FR
        , fl = orientedEdge FL
        , br = orientedEdge BR
        , bl = orientedEdge BL
        }
        { -- Centers
          u = UCenter
        , d = DCenter
        , f = FCenter
        , b = BCenter
        , l = LCenter
        , r = RCenter
        }



-- HELPERS


flip : Cube -> Cube
flip =
    applyAlgorithm <|
        Algorithm.build
            [ Algorithm.Turn Algorithm.Z Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.Y Algorithm.OneQuarter Algorithm.Clockwise
            ]



-- MOVE APPLICATION


type alias TurnDefinition =
    ( MappedPermutation CornerLocation OrientedCorner, MappedPermutation EdgeLocation OrientedEdge, MappedPermutation CenterLocation Center )


composeTurnDefinition : TurnDefinition -> TurnDefinition -> TurnDefinition
composeTurnDefinition ( corners1, edges1, centers1 ) ( corners2, edges2, centers2 ) =
    ( MappedPermutation.compose corners1 corners2
    , MappedPermutation.compose edges1 edges2
    , MappedPermutation.compose centers1 centers2
    )


{-| Apply an algorithm to a cube, see example for [`solved`](Model.Cube#solved)
-}
applyAlgorithm : Algorithm.Algorithm -> Cube -> Cube
applyAlgorithm alg cube =
    List.foldl applyTurn cube (Algorithm.extractInternals alg)


applyTurn : Algorithm.Turn -> Cube -> Cube
applyTurn =
    getTurnDefinition >> applyTurnDefinition


getTurnDefinition : Algorithm.Turn -> TurnDefinition
getTurnDefinition ((Algorithm.Turn turnable _ _) as turn) =
    turnable
        |> getClockwiseQuarterTurnDefinition
        |> toFullTurnDefinition turn


applyTurnDefinition : TurnDefinition -> Cube -> Cube
applyTurnDefinition ( cornerPermutation, edgePermutation, centerPermutation ) =
    MappedPermutation.apply (MappedPermutation.buildAccessor getCorner setCorner) cornerPermutation
        >> MappedPermutation.apply (MappedPermutation.buildAccessor getEdge setEdge) edgePermutation
        >> MappedPermutation.apply (MappedPermutation.buildAccessor getCenter setCenter) centerPermutation



-- First get the clockwise quarter turn permutation


type ClockwiseQuarterTurnDefinition
    = Permutations
        ( ClockwiseQuarterPermutation CornerLocation OrientedCorner
        , ClockwiseQuarterPermutation EdgeLocation OrientedEdge
        , ClockwiseQuarterPermutation CenterLocation Center
        )
    | Composed (List Algorithm.Turn)


type ClockwiseQuarterPermutation location cubie
    = ClockwiseQuarterPermutation (MappedPermutation location cubie)


getClockwiseQuarterTurnDefinition : Algorithm.Turnable -> ClockwiseQuarterTurnDefinition
getClockwiseQuarterTurnDefinition turnable =
    case turnable of
        -- Single face turns
        Algorithm.U ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( U, F, R ), dontTwist )
                  , ( ( U, F, L ), dontTwist )
                  , ( ( U, B, L ), dontTwist )
                  , ( ( U, B, R ), dontTwist )
                  ]
                ]
                [ [ ( M ( U, F ), dontFlip )
                  , ( S ( U, L ), dontFlip )
                  , ( M ( U, B ), dontFlip )
                  , ( S ( U, R ), dontFlip )
                  ]
                ]
                [ noCentersMoved ]

        Algorithm.D ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( D, F, R ), dontTwist )
                  , ( ( D, B, R ), dontTwist )
                  , ( ( D, B, L ), dontTwist )
                  , ( ( D, F, L ), dontTwist )
                  ]
                ]
                [ [ ( M ( D, F ), dontFlip )
                  , ( S ( D, R ), dontFlip )
                  , ( M ( D, B ), dontFlip )
                  , ( S ( D, L ), dontFlip )
                  ]
                ]
                [ noCentersMoved ]

        Algorithm.L ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( U, F, L ), twistCounterClockwise )
                  , ( ( D, F, L ), twistClockwise )
                  , ( ( D, B, L ), twistCounterClockwise )
                  , ( ( U, B, L ), twistClockwise )
                  ]
                ]
                [ [ ( S ( U, L ), dontFlip )
                  , ( E ( F, L ), dontFlip )
                  , ( S ( D, L ), dontFlip )
                  , ( E ( B, L ), dontFlip )
                  ]
                ]
                [ noCentersMoved ]

        Algorithm.R ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( U, F, R ), twistClockwise )
                  , ( ( U, B, R ), twistCounterClockwise )
                  , ( ( D, B, R ), twistClockwise )
                  , ( ( D, F, R ), twistCounterClockwise )
                  ]
                ]
                [ [ ( S ( U, R ), dontFlip )
                  , ( E ( B, R ), dontFlip )
                  , ( S ( D, R ), dontFlip )
                  , ( E ( F, R ), dontFlip )
                  ]
                ]
                [ noCentersMoved ]

        Algorithm.F ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( U, F, L ), twistClockwise )
                  , ( ( U, F, R ), twistCounterClockwise )
                  , ( ( D, F, R ), twistClockwise )
                  , ( ( D, F, L ), twistCounterClockwise )
                  ]
                ]
                [ [ ( M ( U, F ), flipEdge )
                  , ( E ( F, R ), flipEdge )
                  , ( M ( D, F ), flipEdge )
                  , ( E ( F, L ), flipEdge )
                  ]
                ]
                [ noCentersMoved ]

        Algorithm.B ->
            buildClockwiseQuarterTurnDefinition
                [ [ ( ( U, B, R ), twistClockwise )
                  , ( ( U, B, L ), twistCounterClockwise )
                  , ( ( D, B, L ), twistClockwise )
                  , ( ( D, B, R ), twistCounterClockwise )
                  ]
                ]
                [ [ ( M ( U, B ), flipEdge )
                  , ( E ( B, L ), flipEdge )
                  , ( M ( D, B ), flipEdge )
                  , ( E ( B, R ), flipEdge )
                  ]
                ]
                [ noCentersMoved ]

        -- Slice turns
        Algorithm.M ->
            buildClockwiseQuarterTurnDefinition
                [ noCornersMoved ]
                [ [ ( M ( U, B ), flipEdge )
                  , ( M ( U, F ), flipEdge )
                  , ( M ( D, F ), flipEdge )
                  , ( M ( D, B ), flipEdge )
                  ]
                ]
                [ [ ( CenterLocation uFace, identity )
                  , ( CenterLocation fFace, identity )
                  , ( CenterLocation dFace, identity )
                  , ( CenterLocation bFace, identity )
                  ]
                ]

        Algorithm.S ->
            buildClockwiseQuarterTurnDefinition
                [ noCornersMoved ]
                [ [ ( S ( U, L ), flipEdge )
                  , ( S ( U, R ), flipEdge )
                  , ( S ( D, R ), flipEdge )
                  , ( S ( D, L ), flipEdge )
                  ]
                ]
                [ [ ( CenterLocation uFace, identity )
                  , ( CenterLocation rFace, identity )
                  , ( CenterLocation dFace, identity )
                  , ( CenterLocation lFace, identity )
                  ]
                ]

        Algorithm.E ->
            buildClockwiseQuarterTurnDefinition
                [ noCornersMoved ]
                [ [ ( E ( F, L ), flipEdge )
                  , ( E ( F, R ), flipEdge )
                  , ( E ( B, R ), flipEdge )
                  , ( E ( B, L ), flipEdge )
                  ]
                ]
                [ [ ( CenterLocation fFace, identity )
                  , ( CenterLocation rFace, identity )
                  , ( CenterLocation bFace, identity )
                  , ( CenterLocation lFace, identity )
                  ]
                ]

        Algorithm.X ->
            Composed
                [ Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
                , Algorithm.Turn Algorithm.M Algorithm.OneQuarter Algorithm.CounterClockwise
                , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
                ]

        Algorithm.Y ->
            Composed
                [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
                , Algorithm.Turn Algorithm.E Algorithm.OneQuarter Algorithm.CounterClockwise
                , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
                ]

        Algorithm.Z ->
            Composed
                [ Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
                , Algorithm.Turn Algorithm.S Algorithm.OneQuarter Algorithm.Clockwise
                , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
                ]


buildClockwiseQuarterTurnDefinition :
    List (List ( CornerLocation, OrientedCorner -> OrientedCorner ))
    -> List (List ( EdgeLocation, OrientedEdge -> OrientedEdge ))
    -> List (List ( CenterLocation, Center -> Center ))
    -> ClockwiseQuarterTurnDefinition
buildClockwiseQuarterTurnDefinition corners edges centers =
    Permutations
        ( corners |> (MappedPermutation.build >> ClockwiseQuarterPermutation)
        , edges |> (MappedPermutation.build >> ClockwiseQuarterPermutation)
        , centers |> (MappedPermutation.build >> ClockwiseQuarterPermutation)
        )


noCentersMoved : List ( CenterLocation, Center -> Center )
noCentersMoved =
    []


noCornersMoved : List ( CornerLocation, OrientedCorner -> OrientedCorner )
noCornersMoved =
    []



-- Then use the direction and length to convert it to a full turn permutation


toFullTurnDefinition : Algorithm.Turn -> ClockwiseQuarterTurnDefinition -> TurnDefinition
toFullTurnDefinition turn quarterTurnDefinition =
    case quarterTurnDefinition of
        Permutations ( corners, edges, centers ) ->
            ( corners |> toFullPermutation turn
            , edges |> toFullPermutation turn
            , centers |> toFullPermutation turn
            )

        Composed quarterTurns ->
            let
                quarterDefinitions =
                    List.map getTurnDefinition quarterTurns

                ( quarterCorners, quarterEdges, quarterCenters ) =
                    case quarterDefinitions of
                        [] ->
                            ( MappedPermutation.identity, MappedPermutation.identity, MappedPermutation.identity )

                        x :: xs ->
                            List.foldl composeTurnDefinition x xs

                composedQuarterDefinition =
                    Permutations
                        ( ClockwiseQuarterPermutation quarterCorners
                        , ClockwiseQuarterPermutation quarterEdges
                        , ClockwiseQuarterPermutation quarterCenters
                        )
            in
            toFullTurnDefinition turn composedQuarterDefinition


toFullPermutation : Algorithm.Turn -> ClockwiseQuarterPermutation location cubie -> MappedPermutation location cubie
toFullPermutation (Algorithm.Turn _ length direction) (ClockwiseQuarterPermutation permutation) =
    case ( length, direction ) of
        ( Algorithm.OneQuarter, Algorithm.Clockwise ) ->
            permutation

        ( Algorithm.ThreeQuarters, Algorithm.CounterClockwise ) ->
            permutation

        ( Algorithm.Halfway, _ ) ->
            MappedPermutation.toThePowerOf 2 permutation

        ( Algorithm.OneQuarter, Algorithm.CounterClockwise ) ->
            MappedPermutation.reversePermutationButKeepMaps permutation

        ( Algorithm.ThreeQuarters, Algorithm.Clockwise ) ->
            MappedPermutation.reversePermutationButKeepMaps permutation



-- And here are the twists and flips


dontTwist : OrientedCorner -> OrientedCorner
dontTwist =
    identity


twistClockwise : OrientedCorner -> OrientedCorner
twistClockwise (OrientedCorner corner orientation) =
    let
        newOrientation =
            case orientation of
                NotTwisted ->
                    TwistedClockwise

                TwistedClockwise ->
                    TwistedCounterClockwise

                TwistedCounterClockwise ->
                    NotTwisted
    in
    OrientedCorner corner newOrientation


twistCounterClockwise : OrientedCorner -> OrientedCorner
twistCounterClockwise (OrientedCorner corner orientation) =
    let
        newOrientation =
            case orientation of
                NotTwisted ->
                    TwistedCounterClockwise

                TwistedCounterClockwise ->
                    TwistedClockwise

                TwistedClockwise ->
                    NotTwisted
    in
    OrientedCorner corner newOrientation


dontFlip : OrientedEdge -> OrientedEdge
dontFlip =
    identity


flipEdge : OrientedEdge -> OrientedEdge
flipEdge (OrientedEdge corner orientation) =
    let
        newOrientation =
            case orientation of
                NotFlipped ->
                    Flipped

                Flipped ->
                    NotFlipped
    in
    OrientedEdge corner newOrientation



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

    -- Centers
    , u : CubieRendering
    , d : CubieRendering
    , f : CubieRendering
    , b : CubieRendering
    , l : CubieRendering
    , r : CubieRendering
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

        center face =
            renderCenter cube (CenterLocation face)
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

    -- Centers
    , u = center uFace
    , d = center dFace
    , f = center fFace
    , b = center bFace
    , l = center lFace
    , r = center rFace
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



-- CENTER RENDERING


renderCenter : Cube -> CenterLocation -> CubieRendering
renderCenter cube location =
    let
        center =
            getCenter location cube
    in
    plainCubie
        |> setColor (getCentersColoredFace location) (getCentersColor center)


getCentersColoredFace : CenterLocation -> Face
getCentersColoredFace (CenterLocation face) =
    face


getCentersColor : Center -> Color
getCentersColor =
    getSolvedCenterLocation >> getCentersColoredFace >> getColor



-- HELPERS - Mostly just trivial type mappings
-- Corner Location Helpers


getCorner : CornerLocation -> Cube -> OrientedCorner
getCorner location (Cube corners _ _) =
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
setCorner location cornerToSet (Cube corners edges centers) =
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
    Cube newCorners edges centers


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
getEdge location (Cube _ edges _) =
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
setEdge location edgeToSet (Cube corners edges centers) =
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
    Cube corners newEdges centers


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



-- Center Location Helpers


getCenter : CenterLocation -> Cube -> Center
getCenter location (Cube _ _ centers) =
    case location of
        CenterLocation (UpOrDown U) ->
            centers.u

        CenterLocation (UpOrDown D) ->
            centers.d

        CenterLocation (FrontOrBack F) ->
            centers.f

        CenterLocation (FrontOrBack B) ->
            centers.b

        CenterLocation (LeftOrRight L) ->
            centers.l

        CenterLocation (LeftOrRight R) ->
            centers.r


setCenter : CenterLocation -> Center -> Cube -> Cube
setCenter location center (Cube corners edges centers) =
    let
        newCenters =
            case location of
                CenterLocation (UpOrDown U) ->
                    { centers | u = center }

                CenterLocation (UpOrDown D) ->
                    { centers | d = center }

                CenterLocation (FrontOrBack F) ->
                    { centers | f = center }

                CenterLocation (FrontOrBack B) ->
                    { centers | b = center }

                CenterLocation (LeftOrRight L) ->
                    { centers | l = center }

                CenterLocation (LeftOrRight R) ->
                    { centers | r = center }
    in
    Cube corners edges newCenters


getSolvedCenterLocation : Center -> CenterLocation
getSolvedCenterLocation center =
    case center of
        UCenter ->
            CenterLocation uFace

        DCenter ->
            CenterLocation dFace

        FCenter ->
            CenterLocation fFace

        BCenter ->
            CenterLocation bFace

        LCenter ->
            CenterLocation lFace

        RCenter ->
            CenterLocation rFace



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



-- ENUMERATORS


{-| All possible faces

    List.length faces --> 6

-}
faces : List Face
faces =
    let
        fromU face =
            case face of
                UpOrDown U ->
                    Just <| UpOrDown D

                UpOrDown D ->
                    Just <| LeftOrRight L

                LeftOrRight L ->
                    Just <| LeftOrRight R

                LeftOrRight R ->
                    Just <| FrontOrBack F

                FrontOrBack F ->
                    Just <| FrontOrBack B

                FrontOrBack B ->
                    Nothing
    in
    Utils.Enumerator.from (UpOrDown U) fromU


{-| All possible corner locations

    List.length cornerLocations --> 8

-}
cornerLocations : List CornerLocation
cornerLocations =
    let
        fromUFL location =
            case location of
                ( U, F, L ) ->
                    Just ( U, F, R )

                ( U, F, R ) ->
                    Just ( U, B, R )

                ( U, B, R ) ->
                    Just ( U, B, L )

                ( U, B, L ) ->
                    Just ( D, B, L )

                ( D, B, L ) ->
                    Just ( D, B, R )

                ( D, B, R ) ->
                    Just ( D, F, R )

                ( D, F, R ) ->
                    Just ( D, F, L )

                ( D, F, L ) ->
                    Nothing
    in
    Utils.Enumerator.from ( U, F, L ) fromUFL


{-| All possible edge locations

    List.length edgeLocations --> 12

-}
edgeLocations : List EdgeLocation
edgeLocations =
    let
        fromUF location =
            case location of
                M ( U, F ) ->
                    Just <| M ( U, B )

                M ( U, B ) ->
                    Just <| M ( D, B )

                M ( D, B ) ->
                    Just <| M ( D, F )

                M ( D, F ) ->
                    Just <| S ( U, L )

                S ( U, L ) ->
                    Just <| S ( U, R )

                S ( U, R ) ->
                    Just <| S ( D, R )

                S ( D, R ) ->
                    Just <| S ( D, L )

                S ( D, L ) ->
                    Just <| E ( F, L )

                E ( F, L ) ->
                    Just <| E ( F, R )

                E ( F, R ) ->
                    Just <| E ( B, R )

                E ( B, R ) ->
                    Just <| E ( B, L )

                E ( B, L ) ->
                    Nothing
    in
    Utils.Enumerator.from (M ( U, F )) fromUF


{-| All possible center locations

    List.length centerLocations --> 6

-}
centerLocations : List CenterLocation
centerLocations =
    let
        fromU location =
            case location of
                CenterLocation (UpOrDown U) ->
                    Just <| CenterLocation (UpOrDown D)

                CenterLocation (UpOrDown D) ->
                    Just <| CenterLocation (LeftOrRight L)

                CenterLocation (LeftOrRight L) ->
                    Just <| CenterLocation (LeftOrRight R)

                CenterLocation (LeftOrRight R) ->
                    Just <| CenterLocation (FrontOrBack F)

                CenterLocation (FrontOrBack F) ->
                    Just <| CenterLocation (FrontOrBack B)

                CenterLocation (FrontOrBack B) ->
                    Nothing
    in
    Utils.Enumerator.from (CenterLocation (UpOrDown U)) fromU



-- UI STUFF
-- Exports


viewUFRWithLetters : Int -> Cube -> Element.Element msg
viewUFRWithLetters =
    Element.Lazy.lazy2 <| unlazyUFRWithLetters


{-| We need the unlazy version separated as opposed to inline.
If we inline it the javascript reference equality will fail as we're
technically creating a new function in each invocation
-}
unlazyUFRWithLetters : Int -> Cube -> Element.Element msg
unlazyUFRWithLetters =
    getCubeHtml ufrRotation identity


viewUFRNoLetters : Int -> Cube -> Element.Element msg
viewUFRNoLetters =
    Element.Lazy.lazy2 <| unlazyUFRNoLetters


unlazyUFRNoLetters : Int -> Cube -> Element.Element msg
unlazyUFRNoLetters =
    getCubeHtml ufrRotation (always noText)


viewUBLWithLetters : Int -> Cube -> Element.Element msg
viewUBLWithLetters =
    Element.Lazy.lazy2 <| unlazyUBLWithLetters


unlazyUBLWithLetters : Int -> Cube -> Element.Element msg
unlazyUBLWithLetters =
    getCubeHtml (YRotateDegrees 180 :: ufrRotation) identity



-- PARAMETERS


ufrRotation : Transformation
ufrRotation =
    [ ZRotateDegrees 5, XRotateDegrees -15, YRotateDegrees -20 ]


type alias CubeTheme =
    { up : CssColor
    , down : CssColor
    , right : CssColor
    , left : CssColor
    , front : CssColor
    , back : CssColor
    , plastic : CssColor
    }


type alias CssColor =
    String


defaultTheme : CubeTheme
defaultTheme =
    { up = "white"
    , down = "yellow"
    , right = "red"
    , left = "orange"
    , front = "green"
    , back = "blue"
    , plastic = "black"
    }


containerSideLength : Int -> Int
containerSideLength size =
    size * 1


wholeCubeSideLength : Int -> Int
wholeCubeSideLength size =
    containerSideLength size
        |> toFloat
        |> (\x -> x / 1.4)
        |> round


cubieSideLength : Int -> Int
cubieSideLength size =
    wholeCubeSideLength size
        |> toFloat
        |> (\x -> x / 3)
        |> round


cubieBorderWidth : Int -> Int
cubieBorderWidth size =
    cubieSideLength size
        |> toFloat
        |> (\x -> x / 10)
        |> round



-- HTML


type alias Size =
    Int


getCubeHtml : Transformation -> (TextOnFaces msg -> TextOnFaces msg) -> Size -> Cube -> Element.Element msg
getCubeHtml rotation mapText size cube =
    Element.html <|
        let
            rendering =
                render cube
        in
        div
            [ htmlTestid "cube"
            , style "width" (px <| containerSideLength size)
            , style "height" (px <| containerSideLength size)
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            , style "perspective" "0"
            ]
            [ div
                [ style "width" (px <| wholeCubeSideLength size)
                , style "height" (px <| wholeCubeSideLength size)
                , style "position" "relative"
                , style "transform-style" "preserve-3d"
                , cssTransformCube rotation (wholeCubeSideLength size)
                ]
              <|
                List.map (\( a, b, c ) -> displayCubie defaultTheme size b (mapText c) a)
                    (getRenderedCorners rendering ++ getRenderedEdges rendering ++ getRenderedCenters rendering)
            ]


displayCubie : CubeTheme -> Size -> Coordinates -> TextOnFaces msg -> CubieRendering -> Html msg
displayCubie theme size { fromFront, fromLeft, fromTop } textOnFaces rendering =
    div
        [ style "position" "absolute"
        , style "width" (px <| cubieSideLength size)
        , style "height" (px <| cubieSideLength size)
        , style "transform-style" "preserve-3d"
        , style "display" "inline-block"

        -- Position the cubie correctly
        , style "top" (px <| cubieSideLength size * fromTop)
        , style "left" (px <| cubieSideLength size * fromLeft)
        , cssTransformCube [ ZTranslatePixels <| cubieSideLength size * fromFront * -1 ] (cubieSideLength size)
        ]
        (List.map (\face -> displayCubieFace theme size face (getTextForFace textOnFaces face) rendering) faces)


displayCubieFace : CubeTheme -> Size -> Face -> Maybe (String -> Html msg) -> CubieRendering -> Html msg
displayCubieFace theme size face textOnFace rendering =
    div
        [ cssTransformCube [ getFaceRotation face ] (cubieSideLength size)
        , style "background-color" <| getColorString theme (getFaceColor face rendering)
        , style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
        , style "width" (px <| cubieSideLength size)
        , style "height" (px <| cubieSideLength size)
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        , style "border" (theme.plastic ++ " solid " ++ px (cubieBorderWidth size))
        , style "box-sizing" "border-box"
        ]
    <|
        (textOnFace
            |> Maybe.map
                (\actualTextOnFace ->
                    [ actualTextOnFace (px <| cubieSideLength size * 63 // 100) ]
                )
            |> Maybe.withDefault []
        )



-- LOGIC AND MAPPINGS


px : Int -> String
px pixels =
    String.fromInt pixels ++ "px"


getTextForFace : TextOnFaces msg -> Face -> Maybe (String -> Html msg)
getTextForFace textOnFaces face =
    case face of
        UpOrDown U ->
            textOnFaces.u

        UpOrDown D ->
            textOnFaces.d

        FrontOrBack F ->
            textOnFaces.f

        FrontOrBack B ->
            textOnFaces.b

        LeftOrRight L ->
            textOnFaces.l

        LeftOrRight R ->
            textOnFaces.r


getFaceRotation : Face -> SingleTransformation
getFaceRotation face =
    case face of
        UpOrDown U ->
            XRotateDegrees 90

        UpOrDown D ->
            XRotateDegrees -90

        FrontOrBack F ->
            XRotateDegrees 0

        FrontOrBack B ->
            YRotateDegrees 180

        LeftOrRight L ->
            YRotateDegrees -90

        LeftOrRight R ->
            YRotateDegrees 90


getFaceColor : Face -> CubieRendering -> Color
getFaceColor face rendering =
    case face of
        UpOrDown U ->
            rendering.u

        UpOrDown D ->
            rendering.d

        FrontOrBack F ->
            rendering.f

        FrontOrBack B ->
            rendering.b

        LeftOrRight L ->
            rendering.l

        LeftOrRight R ->
            rendering.r


getColorString : CubeTheme -> Color -> String
getColorString theme color =
    case color of
        UpColor ->
            theme.up

        DownColor ->
            theme.down

        RightColor ->
            theme.right

        LeftColor ->
            theme.left

        FrontColor ->
            theme.front

        BackColor ->
            theme.back

        PlasticColor ->
            theme.plastic


{-| We only use ints for now so it makes some things a bit easier
but there's no real reason other than simpler code a few places that they
can't be floats
-}
type alias Coordinates =
    { fromFront : Int
    , fromLeft : Int
    , fromTop : Int
    }


type SingleTransformation
    = XRotateDegrees Int
    | YRotateDegrees Int
    | ZRotateDegrees Int
    | ZTranslatePixels Int


isRotation : SingleTransformation -> Bool
isRotation t =
    case t of
        XRotateDegrees _ ->
            True

        YRotateDegrees _ ->
            True

        ZRotateDegrees _ ->
            True

        ZTranslatePixels _ ->
            False


cssTransformCube : Transformation -> Size -> Attribute msg
cssTransformCube transformation size =
    let
        hasRotations =
            List.filter isRotation transformation
                |> List.length
                |> (\x -> x > 0)

        threeDCompatibleTransformation =
            if hasRotations then
                -- We need this translate as the default center of rotations is at the
                -- "front" of the screen and we need it at the center of the cube.
                -- Note that we can't use transform-origin as it has inconsistent behaviour
                -- in Safari and other browsers
                ZTranslatePixels (size // 2)
                    :: transformation
                    ++ [ ZTranslatePixels (-1 * size // 2) ]

            else
                -- If there aren't any rotations we don't need to move for correct origin
                transformation
    in
    style "transform"
        (threeDCompatibleTransformation
            -- We reverse it as our type reads left to right but
            -- css transform reads right to left
            |> List.reverse
            |> List.map toCssRotationString
            |> String.join " "
        )


toCssRotationString : SingleTransformation -> String
toCssRotationString axisRotation =
    case axisRotation of
        XRotateDegrees deg ->
            "rotateX(" ++ String.fromInt deg ++ "deg)"

        YRotateDegrees deg ->
            "rotateY(" ++ String.fromInt deg ++ "deg)"

        ZRotateDegrees deg ->
            "rotateZ(" ++ String.fromInt deg ++ "deg)"

        ZTranslatePixels pixels ->
            "translateZ(" ++ String.fromInt pixels ++ "px)"


{-| 3D transformation, note that order a difference when it comes to rotations.
The transforms are applied from left to right (note this is opposite to the css transform
property which applies transforms from right to left, but we do left to right for easier
readability here)
-}
type alias Transformation =
    List SingleTransformation


getRenderedCorners : Rendering -> List ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedCorners rendering =
    List.map (getRenderedCorner rendering) cornerLocations


getRenderedCorner : Rendering -> CornerLocation -> ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedCorner rendering location =
    let
        cornerRendering =
            case location of
                ( U, F, L ) ->
                    rendering.ufl

                ( U, F, R ) ->
                    rendering.ufr

                ( U, B, R ) ->
                    rendering.ubr

                ( U, B, L ) ->
                    rendering.ubl

                ( D, B, L ) ->
                    rendering.dbl

                ( D, B, R ) ->
                    rendering.dbr

                ( D, F, R ) ->
                    rendering.dfr

                ( D, F, L ) ->
                    rendering.dfl
    in
    ( cornerRendering, getCornerCoordinates location, noText )


getCornerCoordinates : CornerLocation -> Coordinates
getCornerCoordinates ( uOrD, fOrB, lOrR ) =
    { fromFront =
        if fOrB == F then
            0

        else
            2
    , fromLeft =
        if lOrR == L then
            0

        else
            2
    , fromTop =
        if uOrD == U then
            0

        else
            2
    }


type alias TextOnFaces msg =
    { u : Maybe (String -> Html msg)
    , d : Maybe (String -> Html msg)
    , f : Maybe (String -> Html msg)
    , b : Maybe (String -> Html msg)
    , l : Maybe (String -> Html msg)
    , r : Maybe (String -> Html msg)
    }


noText : TextOnFaces msg
noText =
    { u = Nothing
    , d = Nothing
    , f = Nothing
    , b = Nothing
    , l = Nothing
    , r = Nothing
    }


getRenderedEdges : Rendering -> List ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedEdges rendering =
    List.map (getRenderedEdge rendering) edgeLocations


getRenderedEdge : Rendering -> EdgeLocation -> ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedEdge rendering location =
    let
        edgeRendering =
            case location of
                M ( U, F ) ->
                    rendering.uf

                M ( U, B ) ->
                    rendering.ub

                M ( D, F ) ->
                    rendering.df

                M ( D, B ) ->
                    rendering.db

                S ( U, L ) ->
                    rendering.ul

                S ( U, R ) ->
                    rendering.ur

                S ( D, L ) ->
                    rendering.dl

                S ( D, R ) ->
                    rendering.dr

                E ( F, L ) ->
                    rendering.fl

                E ( F, R ) ->
                    rendering.fr

                E ( B, L ) ->
                    rendering.bl

                E ( B, R ) ->
                    rendering.br
    in
    ( edgeRendering, getEdgeCoordinates location, noText )


getEdgeCoordinates : EdgeLocation -> Coordinates
getEdgeCoordinates location =
    case location of
        M ( uOrD, fOrB ) ->
            { fromFront =
                if fOrB == F then
                    0

                else
                    2
            , fromLeft = 1
            , fromTop =
                if uOrD == U then
                    0

                else
                    2
            }

        S ( uOrD, lOrR ) ->
            { fromFront = 1
            , fromLeft =
                if lOrR == L then
                    0

                else
                    2
            , fromTop =
                if uOrD == U then
                    0

                else
                    2
            }

        E ( fOrB, lOrR ) ->
            { fromFront =
                if fOrB == F then
                    0

                else
                    2
            , fromLeft =
                if lOrR == L then
                    0

                else
                    2
            , fromTop = 1
            }


getRenderedCenters : Rendering -> List ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedCenters rendering =
    List.map (getRenderedCenter rendering) centerLocations


getRenderedCenter : Rendering -> CenterLocation -> ( CubieRendering, Coordinates, TextOnFaces msg )
getRenderedCenter rendering location =
    let
        ( centerRendering, textOnFace ) =
            case location of
                CenterLocation (UpOrDown U) ->
                    ( rendering.u, { noText | u = Just svgU } )

                CenterLocation (UpOrDown D) ->
                    ( rendering.d, { noText | d = Just svgD } )

                CenterLocation (LeftOrRight L) ->
                    ( rendering.l, { noText | l = Just svgL } )

                CenterLocation (LeftOrRight R) ->
                    ( rendering.r, { noText | r = Just svgR } )

                CenterLocation (FrontOrBack F) ->
                    ( rendering.f, { noText | f = Just svgF } )

                CenterLocation (FrontOrBack B) ->
                    ( rendering.b, { noText | b = Just svgB } )
    in
    ( centerRendering, getCenterCoordinates location, textOnFace )


svgF : String -> Html msg
svgF size =
    svg [ viewBox "0 0 150 225", Svg.Attributes.height size ]
        [ line [ x1 "15", y1 "0", x2 "15", y2 "225", stroke "black", strokeWidth "30" ] []
        , line [ x1 "0", y1 "12.5", x2 "150", y2 "12.5", stroke "black", strokeWidth "25" ] []
        , line [ x1 "0", y1 "112.5", x2 "130", y2 "112.5", stroke "black", strokeWidth "25" ] []
        ]


svgL : String -> Html msg
svgL size =
    svg [ viewBox "-15 0 150 225", Svg.Attributes.height size ]
        [ line [ x1 "0", y1 "0", x2 "0", y2 "225", stroke "black", strokeWidth "30" ] []
        , line [ x1 "0", y1 "212.5", x2 "150", y2 "212.5", stroke "black", strokeWidth "25" ] []
        ]


svgU : String -> Html msg
svgU size =
    svg [ viewBox "-17.5 0 219 300", Svg.Attributes.height size ]
        [ path [ d "M 0,0 l 0,200 a 92.5,82.5 0 0 0 185,0 l 0,-200", fill "transparent", strokeWidth "35", stroke "black" ] []
        ]


svgD : String -> Html msg
svgD size =
    svg [ viewBox "-17.5 0 230 290", Svg.Attributes.height size ]
        [ path [ d "M 0,0 l 0,272.5 l 100,0 a 95,127.5 0 0 0 0,-255 l -100,0", fill "transparent", strokeWidth "35", stroke "black" ] []
        ]


svgR : String -> Html msg
svgR size =
    svg [ viewBox "-17.5 0 255 290", Svg.Attributes.height size ]
        [ path [ d "M 0,290 l 0,-272.5 l 100,0 a 95,63.75 0 0 1 0,127.5 l -100,0 l 120,0 l 200,300", fill "transparent", strokeWidth "35", stroke "black" ] []
        ]


svgB : String -> Html msg
svgB size =
    svg [ viewBox "-17.5 0 230 290", Svg.Attributes.height size ]
        [ path [ d "M 0,290 l 0,-272.5 l 100,0 a 95,63.75 0 0 1 0,127.5 l -100,0 m 100,0 a 95,63.75 0 0 1 0,127.5 l -100,0", fill "transparent", strokeWidth "35", stroke "black" ] []
        ]


getCenterCoordinates : CenterLocation -> Coordinates
getCenterCoordinates location =
    case location of
        CenterLocation (UpOrDown U) ->
            { fromFront = 1
            , fromLeft = 1
            , fromTop = 0
            }

        CenterLocation (UpOrDown D) ->
            { fromFront = 1
            , fromLeft = 1
            , fromTop = 2
            }

        CenterLocation (LeftOrRight L) ->
            { fromFront = 1
            , fromLeft = 0
            , fromTop = 1
            }

        CenterLocation (LeftOrRight R) ->
            { fromFront = 1
            , fromLeft = 2
            , fromTop = 1
            }

        CenterLocation (FrontOrBack F) ->
            { fromFront = 0
            , fromLeft = 1
            , fromTop = 1
            }

        CenterLocation (FrontOrBack B) ->
            { fromFront = 2
            , fromLeft = 1
            , fromTop = 1
            }
