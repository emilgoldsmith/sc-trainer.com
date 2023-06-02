module PLL.Extra exposing (PLLAUFPreferences, SymmetricPLL(..), getDefaultPLLPreferences, getPreferredEquivalentAUFs, isSymmetricPLL, preferredAUFsErrorToDebugString)

import AUF exposing (AUF)
import List.Extra
import List.Nonempty
import List.Nonempty.Extra
import PLL exposing (PLL)


type PLLAUFPreferences
    = FullySymmetricPreferences
        ( U2PreOrPost
        , UPreOrPost
        , UPrimePreOrPost
        )
    | HalfSymmetricPreferences
        ( U2PreOrPost
        , OrderOfOppositeQuarterTurns
        , DirectionOfTwoEqualQuarterTurns
        )
    | NPermSymmetricPreferences
        ( U2PreOrPost
        , ClockwisePreAlternatives
        , CounterClockwisePreAlternatives
        )


type SymmetricPLL
    = FullySymmetric PLL.FullySymmetricPLL
    | HalfSymmetric PLL.HalfSymmetricPLL
    | NPermSymmetric PLL.NPermSymmetricPLL


isSymmetricPLL : PLL -> Maybe SymmetricPLL
isSymmetricPLL pll =
    case PLL.getSymmetry pll of
        PLL.FullySymmetric x ->
            Just <| FullySymmetric x

        PLL.HalfSymmetric x ->
            Just <| HalfSymmetric x

        PLL.NPermSymmetric x ->
            Just <| NPermSymmetric x

        PLL.NotSymmetric _ ->
            Nothing


symmetricPLLToPLL : SymmetricPLL -> PLL
symmetricPLLToPLL symPLL =
    case symPLL of
        FullySymmetric x ->
            PLL.fullySymmetricPLLToPLL x

        HalfSymmetric x ->
            PLL.halfSymmetricPLLToPLL x

        NPermSymmetric x ->
            PLL.nPermSymmetricPLLToPLL x


getDefaultPLLPreferences : SymmetricPLL -> PLLAUFPreferences
getDefaultPLLPreferences pll =
    case pll of
        FullySymmetric _ ->
            FullySymmetricPreferences
                ( PostAUFU2
                , PostAUFU
                , PostAUFUPrime
                )

        HalfSymmetric _ ->
            HalfSymmetricPreferences
                ( PostAUFU2
                , ClockwiseBeforeCounter
                , DoubleClockwise
                )

        NPermSymmetric _ ->
            NPermSymmetricPreferences
                ( PostAUFU2
                , CounterPost
                , ClockwisePost
                )


type U2PreOrPost
    = PreAUFU2
    | PostAUFU2


u2PreOrPostToAUFPair : U2PreOrPost -> ( AUF, AUF )
u2PreOrPostToAUFPair x =
    case x of
        PreAUFU2 ->
            ( AUF.Halfway, AUF.None )

        PostAUFU2 ->
            ( AUF.None, AUF.Halfway )


type UPreOrPost
    = PreAUFU
    | PostAUFU


uPreOrPostToAUFPair : UPreOrPost -> ( AUF, AUF )
uPreOrPostToAUFPair x =
    case x of
        PreAUFU ->
            ( AUF.Clockwise, AUF.None )

        PostAUFU ->
            ( AUF.None, AUF.Clockwise )


type UPrimePreOrPost
    = PreAUFUPrime
    | PostAUFUPrime


uPrimePreOrPostToAUFPair : UPrimePreOrPost -> ( AUF, AUF )
uPrimePreOrPostToAUFPair x =
    case x of
        PreAUFUPrime ->
            ( AUF.CounterClockwise, AUF.None )

        PostAUFUPrime ->
            ( AUF.Clockwise, AUF.None )


type OrderOfOppositeQuarterTurns
    = ClockwiseBeforeCounter
    | CounterBeforeClockwise


orderOfOppositeQuarterTurnsToAUFPair : OrderOfOppositeQuarterTurns -> ( AUF, AUF )
orderOfOppositeQuarterTurnsToAUFPair x =
    case x of
        ClockwiseBeforeCounter ->
            ( AUF.Clockwise, AUF.CounterClockwise )

        CounterBeforeClockwise ->
            ( AUF.CounterClockwise, AUF.Clockwise )


type DirectionOfTwoEqualQuarterTurns
    = DoubleCounterClockwise
    | DoubleClockwise


directionOfTwoEqualQuarterTurnsToAUFPair : DirectionOfTwoEqualQuarterTurns -> ( AUF, AUF )
directionOfTwoEqualQuarterTurnsToAUFPair x =
    case x of
        DoubleCounterClockwise ->
            ( AUF.CounterClockwise, AUF.CounterClockwise )

        DoubleClockwise ->
            ( AUF.Clockwise, AUF.Clockwise )


type ClockwisePreAlternatives
    = ClockwisePre
    | CounterPost


clockwisePreAlternativesToAUFPair : ClockwisePreAlternatives -> ( AUF, AUF )
clockwisePreAlternativesToAUFPair x =
    case x of
        ClockwisePre ->
            ( AUF.Clockwise, AUF.None )

        CounterPost ->
            ( AUF.None, AUF.CounterClockwise )


type CounterClockwisePreAlternatives
    = CounterPre
    | ClockwisePost


counterClockwisePreAlternativesToAUFPair : CounterClockwisePreAlternatives -> ( AUF, AUF )
counterClockwisePreAlternativesToAUFPair x =
    case x of
        CounterPre ->
            ( AUF.CounterClockwise, AUF.None )

        ClockwisePost ->
            ( AUF.None, AUF.Clockwise )


pllAUFPreferencesToAUFPairTriple : PLLAUFPreferences -> ( ( AUF, AUF ), ( AUF, AUF ), ( AUF, AUF ) )
pllAUFPreferencesToAUFPairTriple preferences =
    case preferences of
        FullySymmetricPreferences ( a, b, c ) ->
            ( u2PreOrPostToAUFPair a
            , uPreOrPostToAUFPair b
            , uPrimePreOrPostToAUFPair c
            )

        HalfSymmetricPreferences ( a, b, c ) ->
            ( u2PreOrPostToAUFPair a
            , orderOfOppositeQuarterTurnsToAUFPair b
            , directionOfTwoEqualQuarterTurnsToAUFPair c
            )

        NPermSymmetricPreferences ( a, b, c ) ->
            ( u2PreOrPostToAUFPair a
            , clockwisePreAlternativesToAUFPair b
            , counterClockwisePreAlternativesToAUFPair c
            )


aufPairToDebugString : ( AUF, AUF ) -> String
aufPairToDebugString ( a, b ) =
    String.concat
        [ "( "
        , AUF.toString a
        , ", "
        , AUF.toString b
        , " )"
        ]


pllAUFPrerencesToDebugString : PLLAUFPreferences -> String
pllAUFPrerencesToDebugString preferences =
    let
        symmetryTypeString =
            case preferences of
                FullySymmetricPreferences _ ->
                    "Fully Symmetric"

                HalfSymmetricPreferences _ ->
                    "Half Symmetric"

                NPermSymmetricPreferences _ ->
                    "N-perm Symmetric"
    in
    preferences
        |> pllAUFPreferencesToAUFPairTriple
        |> (\( a, b, c ) ->
                String.concat
                    [ "PLL AUF Preferences of symmetry type "
                    , symmetryTypeString
                    , ": "
                    , aufPairToDebugString a
                    , ", "
                    , aufPairToDebugString b
                    , ", "
                    , aufPairToDebugString c
                    ]
           )


type PreferredAUFsError
    = InvalidPreferenceSymmetryType PLLAUFPreferences ( AUF, SymmetricPLL, AUF )
    | UnexpectedInvalidPreferencesError PLLAUFPreferences ( AUF, SymmetricPLL, AUF )


preferredAUFsErrorToDebugString : PreferredAUFsError -> String
preferredAUFsErrorToDebugString error =
    let
        ( generalErrorInfoString, prefs, ( pre, symPLL, post ) ) =
            case error of
                InvalidPreferenceSymmetryType prefs_ ( pre_, symPLL_, post_ ) ->
                    ( "The symmetry type of the pll and of the preferences don't match."
                    , prefs_
                    , ( pre_, symPLL_, post_ )
                    )

                UnexpectedInvalidPreferencesError prefs_ ( pre_, symPLL_, post_ ) ->
                    ( "This error was never expected to occur, but some unknown and unexpected error happened in getPreferredEquivalentAUFs."
                    , prefs_
                    , ( pre_, symPLL_, post_ )
                    )
    in
    String.concat
        [ String.trim generalErrorInfoString
        , " The preferences passed were: "
        , pllAUFPrerencesToDebugString prefs
        , "\n\nAnd the case that was passed as an argument was: "
        , "(\""
        , AUF.toString pre
        , "\", "
        , (PLL.getLetters << symmetricPLLToPLL) symPLL
        , ", \""
        , AUF.toString post
        , "\")"
        ]


getPreferredEquivalentAUFs : PLLAUFPreferences -> ( AUF, SymmetricPLL, AUF ) -> Result PreferredAUFsError ( AUF, AUF )
getPreferredEquivalentAUFs preferences (( preAUF, symPLL, postAUF ) as testCaseTriple) =
    (case ( preferences, symPLL ) of
        ( FullySymmetricPreferences _, FullySymmetric _ ) ->
            Ok ()

        ( FullySymmetricPreferences _, _ ) ->
            Err ()

        ( HalfSymmetricPreferences _, HalfSymmetric _ ) ->
            Ok ()

        ( HalfSymmetricPreferences _, _ ) ->
            Err ()

        ( NPermSymmetricPreferences _, NPermSymmetric _ ) ->
            Ok ()

        ( NPermSymmetricPreferences _, _ ) ->
            Err ()
    )
        |> Result.mapError (always (InvalidPreferenceSymmetryType preferences testCaseTriple))
        |> Result.andThen (always <| preVerifiedGetPreferredEquivalentAUFs preferences testCaseTriple)


preVerifiedGetPreferredEquivalentAUFs : PLLAUFPreferences -> ( AUF, SymmetricPLL, AUF ) -> Result PreferredAUFsError ( AUF, AUF )
preVerifiedGetPreferredEquivalentAUFs preferences (( preAUF, symPLL, postAUF ) as testCaseTriple) =
    let
        optimalOptions =
            ( preAUF, symmetricPLLToPLL symPLL, postAUF )
                |> PLL.getAllEquivalentAUFs
                |> List.Nonempty.Extra.allMinimums
                    (\a b ->
                        -- Lower turn count is always the better option
                        compare (countAUFTurns a) (countAUFTurns b)
                    )
    in
    case optimalOptions of
        List.Nonempty.Nonempty onlyOption [] ->
            -- If only one optimal option we choose that one
            Ok onlyOption

        nonSingletonOptions ->
            -- Else we choose the preference
            preferences
                |> pllAUFPreferencesToAUFPairTriple
                |> (\( a, b, c ) -> [ a, b, c ])
                |> List.Extra.find
                    (\pref ->
                        nonSingletonOptions
                            |> List.Nonempty.Extra.find (\option -> option == pref)
                            |> (/=) Nothing
                    )
                |> Result.fromMaybe (UnexpectedInvalidPreferencesError preferences testCaseTriple)


countAUFTurns : ( AUF, AUF ) -> Float
countAUFTurns ( preAUF, postAUF ) =
    countSingleAUFTurns preAUF + countSingleAUFTurns postAUF


countSingleAUFTurns : AUF -> Float
countSingleAUFTurns auf =
    case auf of
        AUF.None ->
            0

        -- Just anything between 1 and 1.5 really will do the trick for this usecase
        -- as it will never add a full 1 with two numbers added together but be more than a quarter turn
        AUF.Halfway ->
            1.2

        AUF.Clockwise ->
            1

        AUF.CounterClockwise ->
            1
