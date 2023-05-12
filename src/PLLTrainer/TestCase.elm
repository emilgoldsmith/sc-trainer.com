module PLLTrainer.TestCase exposing (Generator, TestCase, build, generate, getGenerator, isNewCaseGenerator, pll, postAUF, preAUF, toAlg, toCube, toTriple)

import AUF exposing (AUF)
import Algorithm
import Cube exposing (Cube)
import List.Extra
import List.Nonempty
import PLL exposing (PLL)
import PLL.Extra
import Random
import Time
import User exposing (User)


type TestCase
    = TestCase ( AUF, PLL, AUF )


build : AUF -> PLL -> AUF -> TestCase
build preAUF_ pll_ postAUF_ =
    let
        ( optimizedPreAUF, optimizedPostAUF ) =
            PLL.Extra.getPreferredEquivalentAUFs
                (User.defaultPLLAUFPreferences pll_)
                ( preAUF_, pll_, postAUF_ )
                -- TODO: Make this return an error
                |> Result.withDefault ( AUF.None, AUF.None )
    in
    TestCase (Debug.log "build result" ( optimizedPreAUF, pll_, optimizedPostAUF ))


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


getNewCaseIfNeeded : User -> Maybe TestCase
getNewCaseIfNeeded user =
    getNextNewCase user
        |> Maybe.map TestCase



-- |> Maybe.map (\( preAUF_, pll_, postAUF_ ) -> build preAUF_ pll_ postAUF_)


getNextNewCase : User -> Maybe ( AUF, PLL, AUF )
getNextNewCase user =
    let
        maybeNewPreAUFCase : Maybe ( AUF, PLL, AUF )
        maybeNewPreAUFCase =
            learningOrderForFixedPLLAlgorithms
                |> List.Extra.findMap (isNewPreAUFCase user)
    in
    case maybeNewPreAUFCase of
        Just newPreAUFCase ->
            Just <| newPreAUFCase

        Nothing ->
            PLL.all
                |> List.Nonempty.toList
                |> List.Extra.findMap (getNewPostAUFCase user)



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

        maybeEquivalentPreAUF : Maybe AUF
        maybeEquivalentPreAUF =
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
    maybeEquivalentPreAUF
        |> Maybe.andThen
            (\equivalentPreAUF ->
                let
                    preAUFAttempted : Bool
                    preAUFAttempted =
                        User.getAttemptedPLLPreAUFs pll_ user
                            |> List.any ((==) equivalentPreAUF)

                    attemptedPostAUFs : List AUF
                    attemptedPostAUFs =
                        User.getAttemptedPLLPostAUFs pll_ user
                in
                -- TODO: Make sure postAUFs of attempted preAUFs are also tested
                if preAUFAttempted then
                    Nothing

                else
                    let
                        _ =
                            Debug.log "preAUF" preAUF_
                    in
                    Just
                        ( Debug.log "equivalentPreAUF" equivalentPreAUF
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


getNewPostAUFCase : User ->  PLL  -> Maybe ( AUF, PLL, AUF )
getNewPostAUFCase user pll_ =
    let
        attemptedPreAUFs : List AUF
        attemptedPreAUFs = User.getAttemptedPLLPreAUFs pll_ user

        -- TODO: Randomize order of this list
        notYetAttemptedPreAUFs = AUF.all
            |> List.Nonempty.toList
            |> List.filter
                (\postAUF_ ->
                    attemptedPostAUFs
                        |> List.all ((/=) postAUF_)
                )
        attemptedPostAUFs : List AUF
        attemptedPostAUFs =
            User.getAttemptedPLLPostAUFs pll_ user

        notYetAttemptedPostAUFs = AUF.all
            |> List.Nonempty.toList
            |> List.filter ((/=) AUF.None)
            |> List.filter
                (\postAUF_ ->
                    attemptedPostAUFs
                        |> List.all ((/=) postAUF_)
                )

        notYetAttemptedAUFPairs = notYetAttemptedPreAUFs
            |> List.concatMap (\preAUF_ -> notYetAttemptedPostAUFs
                |> List.map (Tuple.pair preAUF_))

    in

        |> List.head
        |> Maybe.map
            (\newPostAUF ->
                ( preAUF_
                , pll_
                , newPostAUF
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


generate : { now : Time.Posix, overrideWithConstantValue : Maybe TestCase } -> User -> Generator
generate { now, overrideWithConstantValue } user =
    Debug.log "generated" <|
        case overrideWithConstantValue of
            Just testCaseOverride ->
                buildConstantGenerator user testCaseOverride

            Nothing ->
                case getNewCaseIfNeeded user of
                    Just newCase ->
                        buildConstantGenerator user newCase

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
