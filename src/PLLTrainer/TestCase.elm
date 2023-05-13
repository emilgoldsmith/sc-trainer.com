module PLLTrainer.TestCase exposing (Generator, TestCase, build, escapeHatch, generate, getGenerator, isNewCaseGenerator, pll, postAUF, preAUF, toAlg, toCube, toTriple)

import AUF exposing (AUF)
import Algorithm
import Cube exposing (Cube)
import List.Extra
import List.Nonempty
import List.Nonempty.Extra
import PLL exposing (PLL)
import PLL.Extra
import Ports
import Random
import Random.List
import Time
import User exposing (User)


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : AUF -> PLL -> AUF -> Result (Cmd msg) TestCase
build preAUF_ pll_ postAUF_ =
    let
        optimizedAUFsResult =
            PLL.Extra.getPreferredEquivalentAUFs
                (User.defaultPLLAUFPreferences pll_)
                ( preAUF_, pll_, postAUF_ )
    in
    optimizedAUFsResult
        |> Result.map
            (\( optimizedPreAUF, optimizedPostAUF ) ->
                TestCase ( optimizedPreAUF, pll_, optimizedPostAUF )
            )
        |> Result.mapError PLL.Extra.preferredAUFsErrorToDebugString
        |> Result.mapError Ports.logError


escapeHatch : ( AUF, PLL, AUF ) -> TestCase
escapeHatch =
    TestCase


toAlg : { addFinalReorientationToAlgorithm : Bool } -> User -> TestCase -> Algorithm.Algorithm
toAlg { addFinalReorientationToAlgorithm } user (TestCase ( preAUF_, pll_, postAUF_ )) =
    let
        baseAlgorithm =
            User.getPLLAlgorithm pll_ user
                |> Maybe.withDefault (PLL.getAlgorithm PLL.referenceAlgorithms pll_)
                |> (if addFinalReorientationToAlgorithm then
                        Cube.makeAlgorithmMaintainOrientation

                    else
                        identity
                   )
    in
    baseAlgorithm
        |> Cube.addAUFsToAlgorithm ( preAUF_, postAUF_ )


toTriple : TestCase -> ( AUF, PLL, AUF )
toTriple (TestCase triple) =
    triple


{-| A cube that would be solved by this test case
-}
toCube : User -> TestCase -> Cube
toCube user testCase =
    Cube.solved
        |> Cube.applyAlgorithm
            (Algorithm.inverse <|
                -- We want the final reorientation or we will display the cube in the wrong
                -- orientation
                toAlg { addFinalReorientationToAlgorithm = True } user testCase
            )


preAUF : TestCase -> AUF
preAUF (TestCase ( x, _, _ )) =
    x


pll : TestCase -> PLL
pll (TestCase ( _, x, _ )) =
    x


postAUF : TestCase -> AUF
postAUF (TestCase ( _, _, x )) =
    x


type Generator
    = AlreadyAttempted (Random.Generator TestCase)
    | NewCase (Random.Generator TestCase)


getGenerator : Generator -> Random.Generator TestCase
getGenerator generator =
    case generator of
        AlreadyAttempted x ->
            x

        NewCase x ->
            x


isNewCaseGenerator : Generator -> Bool
isNewCaseGenerator generator =
    case generator of
        NewCase _ ->
            True

        AlreadyAttempted _ ->
            False


replaceInternalGenerator : Random.Generator TestCase -> Generator -> Generator
replaceInternalGenerator newInternalGenerator oldGenerator =
    case oldGenerator of
        NewCase _ ->
            NewCase newInternalGenerator

        AlreadyAttempted _ ->
            AlreadyAttempted newInternalGenerator


buildConstantGenerator : User -> TestCase -> Generator
buildConstantGenerator user testCase =
    if User.pllTestCaseIsNewForUser (toTriple testCase) user then
        NewCase (Random.constant testCase)

    else
        AlreadyAttempted (Random.constant testCase)


getNewCaseIfNeeded : User -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
getNewCaseIfNeeded user =
    getNextNewCase user


getNextNewCase : User -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
getNextNewCase user =
    let
        maybeNewPreAUFCase : Maybe ( AUF, PLL, AUF )
        maybeNewPreAUFCase =
            learningOrderForFixedPLLAlgorithms
                |> List.Extra.findMap (isNewPreAUFCase user)
    in
    Debug.log "next new case result" <|
        case maybeNewPreAUFCase of
            Just ( pre, pll_, post ) ->
                build pre pll_ post
                    |> Result.map Random.constant
                    |> Result.map Just

            Nothing ->
                PLL.all
                    |> List.Nonempty.toList
                    |> List.map (getNewPostAUFCase user)
                    -- Convert list of errors to error of list
                    |> List.foldl
                        (\next result ->
                            case ( result, next ) of
                                ( Ok list, Ok nextCase ) ->
                                    Ok (nextCase :: list)

                                ( Ok list, Err nextErr ) ->
                                    Err nextErr

                                ( Err cmd, Ok _ ) ->
                                    Err cmd

                                ( Err cmd, Err nextErr ) ->
                                    Err (Cmd.batch [ cmd, nextErr ])
                        )
                        (Ok [])
                    |> Result.map
                        (List.filterMap identity
                            >> List.Nonempty.fromList
                            >> Maybe.map
                                -- Convert list of generators to generator of list
                                ((\(List.Nonempty.Nonempty firstElem rest) ->
                                    List.foldl
                                        (\next cur ->
                                            Random.map2 List.Nonempty.cons
                                                next
                                                cur
                                        )
                                        (firstElem |> Random.map List.Nonempty.singleton)
                                        rest
                                 )
                                    >> Random.andThen List.Nonempty.Extra.choose
                                    >> Random.map Tuple.first
                                )
                        )



-- TODO: Refactor this properly


isNewPreAUFCase : User -> ( AUF, PLL ) -> Maybe ( AUF, PLL, AUF )
isNewPreAUFCase user ( preAUF_, pll_ ) =
    let
        currentAlgorithm : Algorithm.Algorithm
        currentAlgorithm =
            toAlg
                { addFinalReorientationToAlgorithm = False }
                user
                (TestCase ( AUF.None, pll_, AUF.None ))

        maybePreAUFForReferenceAlg : Maybe AUF
        maybePreAUFForReferenceAlg =
            Cube.detectAUFs
                { toDetectFor = currentAlgorithm
                , toMatchTo =
                    Algorithm.append
                        (AUF.toAlgorithm preAUF_)
                    <|
                        Algorithm.append (PLL.getAlgorithm fixedShortPLLAlgorithms pll_) <|
                            AUF.toAlgorithm AUF.None
                }
                |> Maybe.map (\( pre, _ ) -> pre)
    in
    maybePreAUFForReferenceAlg
        |> Maybe.andThen
            (\preAUFForReferenceAlg ->
                let
                    equivalentPreAUFs : List.Nonempty.Nonempty AUF
                    equivalentPreAUFs =
                        -- Doesn't matter what we put as the post AUF as it won't change the equivalent pre AUFs
                        PLL.getAllEquivalentAUFs ( preAUFForReferenceAlg, pll_, AUF.None )
                            |> List.Nonempty.map Tuple.first

                    preAUFAttempted : Bool
                    preAUFAttempted =
                        User.getAttemptedPLLPreAUFs pll_ user
                            |> List.any (\attemptedPreAUF -> List.Nonempty.member attemptedPreAUF equivalentPreAUFs)

                    attemptedPostAUFs : List AUF
                    attemptedPostAUFs =
                        User.getAttemptedPLLPostAUFs pll_ user
                in
                if preAUFAttempted then
                    Nothing

                else
                    let
                        _ =
                            Debug.log "preAUF" preAUF_
                    in
                    Just
                        ( Debug.log "equivalentPreAUF" preAUFForReferenceAlg
                        , pll_
                          -- TODO: Randomize order of this list
                        , AUF.all
                            |> List.Nonempty.toList
                            |> List.filter ((/=) AUF.None)
                            |> List.filter
                                (\postAUF_ ->
                                    attemptedPostAUFs
                                        |> List.all ((/=) postAUF_)
                                )
                            |> List.head
                            -- TODO: Make this random
                            |> Maybe.withDefault AUF.None
                        )
            )


getNewPostAUFCase : User -> PLL -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
getNewPostAUFCase user pll_ =
    let
        attemptedPreAUFs : List AUF
        attemptedPreAUFs =
            User.getAttemptedPLLPreAUFs (Debug.log "pll" pll_) user
                |> Debug.log "attemptedPreAUFs"

        attemptedPostAUFs : List AUF
        attemptedPostAUFs =
            -- We add None here as we don't crea about learning none post AUF cases
            AUF.None
                :: User.getAttemptedPLLPostAUFs pll_ user
                |> Debug.log "attemptedPostAUFs"

        allTestCases =
            AUF.all
                |> List.Nonempty.toList
                |> List.concatMap
                    (\preAUF_ ->
                        AUF.all
                            |> List.Nonempty.toList
                            |> List.map (build preAUF_ pll_)
                    )
                |> List.foldl
                    (\next result ->
                        case ( result, next ) of
                            ( Ok list, Ok nextCase ) ->
                                Ok (nextCase :: list)

                            ( Ok list, Err nextErr ) ->
                                Err nextErr

                            ( Err cmd, Ok _ ) ->
                                Err cmd

                            ( Err cmd, Err nextErr ) ->
                                Err (Cmd.batch [ cmd, nextErr ])
                    )
                    (Ok [])
                |> Result.map List.Extra.unique
                |> Debug.log "allTestCases"

        allUnseenTestCases : Result (Cmd msg) (List TestCase)
        allUnseenTestCases =
            allTestCases
                |> Result.map
                    (List.filter
                        (\(TestCase ( preAUF_, _, postAUF_ )) ->
                            not (List.member preAUF_ attemptedPreAUFs) || not (List.member postAUF_ attemptedPostAUFs)
                        )
                    )
                |> Debug.log "all unseen"

        numAttemptedPartition =
            allUnseenTestCases
                |> Result.map
                    (List.partition
                        (\(TestCase ( preAUF_, _, postAUF_ )) ->
                            not (List.member preAUF_ attemptedPreAUFs) && not (List.member postAUF_ attemptedPostAUFs)
                        )
                    )
                |> Debug.log "partition"
    in
    Debug.log "new post auf case result" <|
        -- NOTE: One could write a recursion here to make sure we pick
        -- the most efficient way of learning all the different AUFs
        -- in as few attempts as possible, but:
        -- 1. It probably isn't too impactful for the user making that further optimization
        -- 2. This is actually already optimal as it is impossible after all recognition angles
        -- have been taught (each with a unique postAUF) to come up with a case where
        -- preAUFsLeft + postAUFsLeft > 3, try it yourself.
        (numAttemptedPartition
            |> Result.map
                (\( bothNotAttempted, singleNotAttempted ) ->
                    case List.Nonempty.fromList bothNotAttempted of
                        Just nonemptyBothNotAttempted ->
                            List.Nonempty.Extra.choose nonemptyBothNotAttempted
                                |> Random.map Tuple.first
                                |> Just

                        Nothing ->
                            singleNotAttempted
                                |> List.Nonempty.fromList
                                |> Maybe.map List.Nonempty.Extra.choose
                                |> Maybe.map (Random.map <| Tuple.first)
                )
        )


learningOrderForFixedPLLAlgorithms : List ( AUF, PLL )
learningOrderForFixedPLLAlgorithms =
    [ ( AUF.None, PLL.H )
    , ( AUF.None, PLL.Z )
    , ( AUF.CounterClockwise, PLL.Ua )
    , ( AUF.Halfway, PLL.Ub )
    , ( AUF.None, PLL.Y )
    , ( AUF.Clockwise, PLL.Ja )
    , ( AUF.Halfway, PLL.Jb )
    , ( AUF.Clockwise, PLL.Aa )
    , ( AUF.Halfway, PLL.Ab )
    , ( AUF.Clockwise, PLL.V )
    , ( AUF.None, PLL.F )
    , ( AUF.None, PLL.Na )
    , ( AUF.None, PLL.Nb )
    , ( AUF.Halfway, PLL.T )
    , ( AUF.Halfway, PLL.Ra )
    , ( AUF.Halfway, PLL.Rb )
    , ( AUF.CounterClockwise, PLL.Y )
    , ( AUF.Clockwise, PLL.Y )
    , ( AUF.Clockwise, PLL.Ga )
    , ( AUF.CounterClockwise, PLL.Gc )
    , ( AUF.CounterClockwise, PLL.Gb )
    , ( AUF.None, PLL.Gd )
    , ( AUF.Halfway, PLL.Y )
    , ( AUF.CounterClockwise, PLL.V )
    , ( AUF.CounterClockwise, PLL.E )
    , ( AUF.Halfway, PLL.E )
    , ( AUF.Clockwise, PLL.F )
    , ( AUF.None, PLL.Ja )
    , ( AUF.Clockwise, PLL.Jb )
    , ( AUF.Halfway, PLL.Ua )
    , ( AUF.CounterClockwise, PLL.Ub )
    , ( AUF.Clockwise, PLL.Z )
    , ( AUF.None, PLL.Ua )
    , ( AUF.Clockwise, PLL.Ub )
    , ( AUF.Clockwise, PLL.Ua )
    , ( AUF.None, PLL.Ub )
    , ( AUF.CounterClockwise, PLL.T )
    , ( AUF.Halfway, PLL.Aa )
    , ( AUF.Clockwise, PLL.Ab )
    , ( AUF.Halfway, PLL.Ga )
    , ( AUF.Halfway, PLL.Gc )
    , ( AUF.CounterClockwise, PLL.Ra )
    , ( AUF.Clockwise, PLL.Rb )
    , ( AUF.CounterClockwise, PLL.Ga )
    , ( AUF.Clockwise, PLL.Gc )
    , ( AUF.Clockwise, PLL.Gb )
    , ( AUF.Halfway, PLL.Gb )
    , ( AUF.Clockwise, PLL.Gd )
    , ( AUF.Halfway, PLL.Gd )
    , ( AUF.CounterClockwise, PLL.Aa )
    , ( AUF.CounterClockwise, PLL.Ab )
    , ( AUF.Halfway, PLL.Ja )
    , ( AUF.CounterClockwise, PLL.Ja )
    , ( AUF.None, PLL.Jb )
    , ( AUF.CounterClockwise, PLL.Jb )
    , ( AUF.None, PLL.V )
    , ( AUF.Halfway, PLL.V )
    , ( AUF.Clockwise, PLL.Ra )
    , ( AUF.CounterClockwise, PLL.Rb )
    , ( AUF.None, PLL.Gb )
    , ( AUF.CounterClockwise, PLL.Gd )
    , ( AUF.Clockwise, PLL.T )
    , ( AUF.None, PLL.T )
    , ( AUF.None, PLL.Aa )
    , ( AUF.None, PLL.Ab )
    , ( AUF.CounterClockwise, PLL.F )
    , ( AUF.Halfway, PLL.F )
    , ( AUF.None, PLL.Ra )
    , ( AUF.None, PLL.Rb )
    , ( AUF.None, PLL.Ga )
    , ( AUF.None, PLL.Gc )
    ]


generate : { now : Time.Posix, overrideWithConstantValue : Maybe TestCase } -> User -> Result (Cmd msg) Generator
generate { now, overrideWithConstantValue } user =
    Debug.log "generated" <|
        case overrideWithConstantValue of
            Just testCaseOverride ->
                Ok <| buildConstantGenerator user testCaseOverride

            Nothing ->
                getNewCaseIfNeeded user
                    |> Result.map
                        (\newCaseIfNeeded ->
                            case newCaseIfNeeded of
                                Just newCaseGenerator ->
                                    NewCase newCaseGenerator

                                Nothing ->
                                    let
                                        { pllGenerator, generatorType } =
                                            generatePLL { now = now } user

                                        testCaseGenerator =
                                            Random.map TestCase <|
                                                Random.map3 (\a b c -> ( a, b, c ))
                                                    (List.Nonempty.sample AUF.all)
                                                    pllGenerator
                                                    (List.Nonempty.sample AUF.all)
                                    in
                                    replaceInternalGenerator testCaseGenerator generatorType
                        )


generatePLL :
    { now : Time.Posix }
    -> User
    -> { pllGenerator : Random.Generator PLL, generatorType : Generator }
generatePLL { now } user =
    let
        statistics =
            User.pllStatistics user

        notAttemptedYets =
            List.filterMap
                (\stat ->
                    case stat of
                        User.CaseNotAttemptedYet pll_ ->
                            Just pll_

                        _ ->
                            Nothing
                )
                statistics

        notYetLearneds =
            List.filterMap
                (\stat ->
                    case stat of
                        User.HasRecentDNF pll_ ->
                            Just pll_

                        _ ->
                            Nothing
                )
                statistics

        fullyLearneds =
            List.filterMap
                (\stat ->
                    case stat of
                        User.AllRecentAttemptsSucceeded record ->
                            Just
                                ( toFloat
                                    (Time.posixToMillis now - Time.posixToMillis record.lastTimeTested)
                                    * record.lastThreeAverageTPS
                                , record.pll
                                )

                        _ ->
                            Nothing
                )
                statistics
    in
    case ( notAttemptedYets, notYetLearneds, fullyLearneds ) of
        ( head :: tail, _, _ ) ->
            { pllGenerator = Random.uniform head tail, generatorType = NewCase (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        ( _, head :: tail, _ ) ->
            { pllGenerator = Random.uniform head tail, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        ( _, _, head :: tail ) ->
            { pllGenerator = Random.weighted head tail, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }

        -- This should never occur as there should always be at least one list with elements in it
        _ ->
            { pllGenerator = Random.constant PLL.Aa, generatorType = AlreadyAttempted (Random.constant <| TestCase ( AUF.None, PLL.Aa, AUF.None )) }


{-| Be aware that changing these algorithms could require
changing code in some of the functions above if it changes the execution angles
or post AUFs required as code in above functions depend on the angles and post AUFs
-}
fixedShortPLLAlgorithms : PLL.Algorithms
fixedShortPLLAlgorithms =
    { h =
        Algorithm.fromTurnList
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
        Algorithm.fromTurnList
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
        Algorithm.fromTurnList
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
        Algorithm.fromTurnList
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
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            ]
    , ab =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            ]
    , e =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            ]
    , f =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            ]
    , ga =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            ]
    , gb =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            ]
    , gc =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            ]
    , gd =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            ]
    , ja =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.Halfway Algorithm.Clockwise
            ]
    , jb =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            ]
    , na =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            ]
    , nb =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.OneQuarter Algorithm.Clockwise
            ]
    , ra =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            ]
    , rb =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.F Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            ]
    , t =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.L Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.L Algorithm.Halfway Algorithm.Clockwise
            ]
    , v =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.B Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            ]
    , y =
        Algorithm.fromTurnList
            [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.D Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
            ]
    }
