module PLLTrainer.TestCase exposing (Generator, TestCase, build, escapeHatch, generate, getGenerator, isNewCaseGenerator, pll, postAUF, preAUF, toAlg, toCube, toTriple)

import AUF exposing (AUF)
import Algorithm
import Cube exposing (Cube)
import List.Extra
import List.Nonempty
import PLL exposing (PLL)
import PLL.Extra
import Ports
import Random
import Time
import User exposing (User)


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : User -> AUF -> PLL -> AUF -> Result (Cmd msg) TestCase
build user preAUF_ pll_ postAUF_ =
    let
        optimizedAUFsResult =
            PLL.Extra.isSymmetricPLL pll_
                |> Maybe.map
                    (\symPLL ->
                        PLL.Extra.getPreferredEquivalentAUFs
                            (User.getPLLAUFPreferences symPLL user
                                |> Maybe.withDefault
                                    (PLL.Extra.getDefaultPLLPreferences symPLL)
                            )
                            ( preAUF_, symPLL, postAUF_ )
                    )
                -- If it's not symmetric it's already optimized
                |> Maybe.withDefault (Ok ( preAUF_, postAUF_ ))
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


generate : { now : Time.Posix, overrideWithConstantValue : Maybe TestCase } -> User -> Result (Cmd msg) Generator
generate { now, overrideWithConstantValue } user =
    case overrideWithConstantValue of
        Just testCaseOverride ->
            Ok <| buildConstantGenerator user testCaseOverride

        Nothing ->
            generateNewCase user
                |> Result.andThen
                    (\maybeNewCaseGenerator ->
                        case maybeNewCaseGenerator of
                            Just newCaseGenerator ->
                                Ok <| NewCase newCaseGenerator

                            Nothing ->
                                generateAlreadyAttemptedCase { now = now } user
                                    |> Result.map AlreadyAttempted
                    )


buildConstantGenerator : User -> TestCase -> Generator
buildConstantGenerator user testCase =
    if User.pllTestCaseIsNewForUser (toTriple testCase) user then
        NewCase (Random.constant testCase)

    else
        AlreadyAttempted (Random.constant testCase)


generateNewCase : User -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
generateNewCase user =
    learningOrderForFixedPLLAlgorithms
        -- Get the equivalent pre auf for the user's utilized alg
        |> List.map
            (\( referencePreAUF, pll_ ) ->
                referencePreAUFToUserAlgPreAUF user ( referencePreAUF, pll_ )
                    |> Result.map (Tuple.pair pll_)
            )
        |> listOfResultsToResultOfList
        -- Generate new recognition angle case if one is left
        |> Result.andThen
            (List.map
                (\( pll_, preAUFForUserAlg ) ->
                    if isRecognitionAngleAttempted user ( preAUFForUserAlg, pll_ ) then
                        Ok Nothing

                    else
                        generateNewPostAUFCaseForPreAUF user ( preAUFForUserAlg, pll_ )
                            |> Result.andThen
                                (\maybeNewPostAUFCase ->
                                    case maybeNewPostAUFCase of
                                        Just x ->
                                            Ok <| Just x

                                        Nothing ->
                                            AUF.all
                                                |> List.Nonempty.map (build user preAUFForUserAlg pll_)
                                                |> nonemptyListOfResultsToResultOfList
                                                |> Result.map (List.Nonempty.sample >> Just)
                                )
                )
                >> listOfResultsToResultOfList
            )
        -- Find the first one that wasn't Nothing
        |> Result.map (List.Extra.findMap identity)
        |> Result.andThen
            (\newRecognitionAngleTestCase ->
                case newRecognitionAngleTestCase of
                    Just x ->
                        Ok <| Just x

                    Nothing ->
                        -- If no new recognition angles generate any new case
                        generateAnyNewAUFCase user
            )


generateAlreadyAttemptedCase :
    { now : Time.Posix }
    -> User
    -> Result (Cmd msg) (Random.Generator TestCase)
generateAlreadyAttemptedCase { now } user =
    let
        statistics : List User.CaseStatistics
        statistics =
            User.pllStatistics user

        allAUFPairs : List ( AUF, AUF )
        allAUFPairs =
            AUF.all
                |> List.Nonempty.toList
                |> List.concatMap
                    (\preAUF_ ->
                        AUF.all
                            |> List.Nonempty.toList
                            |> List.map (Tuple.pair preAUF_)
                    )

        notYetLearneds : Result (Cmd msg) (List TestCase)
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
                |> List.concatMap
                    (\pll_ ->
                        allAUFPairs
                            |> List.map (\( pre, post ) -> build user pre pll_ post)
                    )
                |> listOfResultsToResultOfList

        fullyLearneds : Result (Cmd msg) (List ( Float, TestCase ))
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
                |> List.concatMap
                    (\( weight, pll_ ) ->
                        allAUFPairs
                            |> List.map
                                (\( pre, post ) ->
                                    build user pre pll_ post
                                        |> Result.map (Tuple.pair weight)
                                )
                    )
                |> listOfResultsToResultOfList
    in
    case ( notYetLearneds, fullyLearneds ) of
        ( Err a, Err b ) ->
            Err (Cmd.batch [ a, b ])

        ( Err a, Ok _ ) ->
            Err a

        ( Ok _, Err b ) ->
            Err b

        ( Ok (head :: tail), Ok _ ) ->
            Ok <| Random.uniform head tail

        ( Ok _, Ok (head :: tail) ) ->
            Ok <| Random.weighted head tail

        ( Ok [], Ok [] ) ->
            Err (Ports.logError "Both notYetLearneds and fullyLearneds were empty lists")


referencePreAUFToUserAlgPreAUF : User -> ( AUF, PLL ) -> Result (Cmd msg) AUF
referencePreAUFToUserAlgPreAUF user ( preAUF_, pll_ ) =
    let
        currentAlgorithm : Algorithm.Algorithm
        currentAlgorithm =
            toAlg
                { addFinalReorientationToAlgorithm = False }
                user
                (TestCase ( AUF.None, pll_, AUF.None ))

        toMatchTo : Algorithm.Algorithm
        toMatchTo =
            Algorithm.append
                (AUF.toAlgorithm preAUF_)
            <|
                Algorithm.append (PLL.getAlgorithm fixedShortPLLAlgorithms pll_) <|
                    AUF.toAlgorithm AUF.None
    in
    Cube.detectAUFs
        { toDetectFor = currentAlgorithm
        , toMatchTo = toMatchTo
        }
        |> Maybe.map Tuple.first
        |> Result.fromMaybe
            (Ports.logError
                (String.concat
                    [ "Error detecting AUFs in referencePreAUFToUserAlgPreAUF.\n\nThe current algorithm passed in was: "
                    , Algorithm.toString currentAlgorithm
                    , "\n\nThe algorithm to match to was: "
                    , Algorithm.toString toMatchTo
                    , "\n\nThe preAUF was: "
                    , AUF.toString preAUF_
                    , "\n\nAnd the pll was: "
                    , PLL.getLetters pll_
                    ]
                )
            )


isRecognitionAngleAttempted : User -> ( AUF, PLL ) -> Bool
isRecognitionAngleAttempted user ( preAUF_, pll_ ) =
    let
        equivalentPreAUFs : List.Nonempty.Nonempty AUF
        equivalentPreAUFs =
            -- Doesn't matter what we put as the post AUF as it won't change the equivalent pre AUFs
            PLL.getAllEquivalentAUFs ( preAUF_, pll_, AUF.None )
                |> List.Nonempty.map Tuple.first
    in
    User.getAttemptedPLLPreAUFs pll_ user
        |> List.any (\attemptedPreAUF -> List.Nonempty.member attemptedPreAUF equivalentPreAUFs)


generateNewPostAUFCaseForPreAUF : User -> ( AUF, PLL ) -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
generateNewPostAUFCaseForPreAUF user ( preAUF_, pll_ ) =
    let
        allTestCases : Result (Cmd msg) (List TestCase)
        allTestCases =
            AUF.all
                |> List.Nonempty.toList
                |> List.map (build user preAUF_ pll_)
                |> listOfResultsToResultOfList
                |> Result.map List.Extra.unique

        attemptedPostAUFs : List AUF
        attemptedPostAUFs =
            -- We add None here as we don't care about learning none post AUF cases
            AUF.None
                :: User.getAttemptedPLLPostAUFs pll_ user

        allUnseenTestCases : Result (Cmd msg) (List TestCase)
        allUnseenTestCases =
            allTestCases
                |> Result.map
                    (List.filter
                        (\(TestCase ( _, _, postAUF_ )) ->
                            not (List.member postAUF_ attemptedPostAUFs)
                        )
                    )
    in
    allUnseenTestCases
        |> Result.map List.Nonempty.fromList
        |> Result.map (Maybe.map List.Nonempty.sample)


generateAnyNewAUFCase : User -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
generateAnyNewAUFCase user =
    PLL.all
        |> List.Nonempty.toList
        |> List.map (generateAnyNewAUFCaseForPLL user)
        |> listOfResultsToResultOfList
        |> Result.map
            (List.filterMap identity
                >> List.Nonempty.fromList
                >> Maybe.map
                    -- Convert list of generators to generator of list
                    ((\(List.Nonempty.Nonempty firstElem rest) ->
                        List.foldl
                            (Random.map2 List.Nonempty.cons)
                            (firstElem |> Random.map List.Nonempty.singleton)
                            rest
                     )
                        >> Random.andThen List.Nonempty.sample
                    )
            )


generateAnyNewAUFCaseForPLL : User -> PLL -> Result (Cmd msg) (Maybe (Random.Generator TestCase))
generateAnyNewAUFCaseForPLL user pll_ =
    let
        attemptedPreAUFs : List AUF
        attemptedPreAUFs =
            User.getAttemptedPLLPreAUFs pll_ user

        attemptedPostAUFs : List AUF
        attemptedPostAUFs =
            -- We add None here as we don't care about learning none post AUF cases
            AUF.None
                :: User.getAttemptedPLLPostAUFs pll_ user

        allTestCases : Result (Cmd msg) (List TestCase)
        allTestCases =
            AUF.all
                |> List.Nonempty.toList
                |> List.concatMap
                    (\preAUF_ ->
                        AUF.all
                            |> List.Nonempty.toList
                            |> List.map (build user preAUF_ pll_)
                    )
                |> listOfResultsToResultOfList
                |> Result.map List.Extra.unique

        allUnseenTestCases : Result (Cmd msg) (List TestCase)
        allUnseenTestCases =
            allTestCases
                |> Result.map
                    (List.filter
                        (\(TestCase ( preAUF_, _, postAUF_ )) ->
                            not (List.member preAUF_ attemptedPreAUFs) || not (List.member postAUF_ attemptedPostAUFs)
                        )
                    )

        numAttemptedPartition : Result (Cmd msg) ( List TestCase, List TestCase )
        numAttemptedPartition =
            allUnseenTestCases
                |> Result.map
                    (List.partition
                        (\(TestCase ( preAUF_, _, postAUF_ )) ->
                            not (List.member preAUF_ attemptedPreAUFs) && not (List.member postAUF_ attemptedPostAUFs)
                        )
                    )
    in
    -- NOTE: One could write a recursion here to make sure we pick
    -- the most efficient way of learning all the different AUFs
    -- in as few attempts as possible, but:
    -- 1. It probably isn't too impactful for the user making that further optimization
    -- 2. This is actually already optimal as it is impossible after all recognition angles
    -- have been taught (each with a unique postAUF) to come up with a case where
    -- preAUFsLeft + postAUFsLeft > 3, try it yourself.
    numAttemptedPartition
        |> Result.map
            (\( bothNotAttempted, singleNotAttempted ) ->
                case List.Nonempty.fromList bothNotAttempted of
                    Just nonemptyBothNotAttempted ->
                        Just <| List.Nonempty.sample nonemptyBothNotAttempted

                    Nothing ->
                        singleNotAttempted
                            |> List.Nonempty.fromList
                            |> Maybe.map List.Nonempty.sample
            )


listOfResultsToResultOfList : List (Result (Cmd msg) a) -> Result (Cmd msg) (List a)
listOfResultsToResultOfList =
    List.foldl
        (\next result ->
            case ( result, next ) of
                ( Ok list, Ok nextCase ) ->
                    Ok (nextCase :: list)

                ( Ok _, Err nextErr ) ->
                    Err nextErr

                ( Err cmd, Ok _ ) ->
                    Err cmd

                ( Err cmd, Err nextErr ) ->
                    Err (Cmd.batch [ cmd, nextErr ])
        )
        (Ok [])


nonemptyListOfResultsToResultOfList : List.Nonempty.Nonempty (Result (Cmd msg) a) -> Result (Cmd msg) (List.Nonempty.Nonempty a)
nonemptyListOfResultsToResultOfList (List.Nonempty.Nonempty head tail) =
    List.foldl
        (\next result ->
            case ( result, next ) of
                ( Ok list, Ok nextCase ) ->
                    Ok (List.Nonempty.cons nextCase list)

                ( Ok _, Err nextErr ) ->
                    Err nextErr

                ( Err cmd, Ok _ ) ->
                    Err cmd

                ( Err cmd, Err nextErr ) ->
                    Err (Cmd.batch [ cmd, nextErr ])
        )
        (Result.map List.Nonempty.singleton head)
        tail


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
