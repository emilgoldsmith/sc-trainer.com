module User exposing
    ( User
    , new
    , getPLLAlgorithm, changePLLAlgorithm, hasChosenPLLAlgorithmFor
    , hasAttemptedAnyPLLTestCase, getPLLTargetParameters, changePLLTargetParameters, pllTestCaseIsNewForUser
    , hasChosenPLLTargetParameters, cubeTheme
    , TestResult(..), testResultPreAUF, testResultPostAUF, testTimestamp, RecordResultError(..), recordPLLTestResult
    , CaseStatistics(..), pllStatistics, orderByWorstCaseFirst
    , serialize, deserialize
    )

{-|


# Type

@docs User


# Constructors

@docs new


# Getters And Setters

@docs getPLLAlgorithm, changePLLAlgorithm, hasChosenPLLAlgorithmFor
@docs hasAttemptedAnyPLLTestCase, getPLLTargetParameters, changePLLTargetParameters, pllTestCaseIsNewForUser
@docs hasChosenPLLTargetParameters, cubeTheme


# Event Handling

@docs TestResult, testResultPreAUF, testResultPostAUF, testTimestamp, RecordResultError, recordPLLTestResult


# Statistics

@docs CaseStatistics, pllStatistics, orderByWorstCaseFirst


# (De)serialization

@docs serialize, deserialize

-}

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Algorithm.Extra
import Cube.Advanced
import Dict exposing (Dict)
import Json.Decode
import Json.Encode
import List.Nonempty
import PLL exposing (PLL)
import Time


{-| The User type
-}
type User
    = User PLLTrainerData Cube.Advanced.CubeTheme


type alias PLLTrainerData =
    { targetParameters : Maybe PLLTargetParameters
    , pllData : PLLData
    }


type alias PLLTargetParameters =
    { recognitionTimeInSeconds : Float, tps : Float }


type alias PLLData =
    { -- Edges only
      h : Maybe ( Algorithm, List TestResult )
    , ua : Maybe ( Algorithm, List TestResult )
    , ub : Maybe ( Algorithm, List TestResult )
    , z : Maybe ( Algorithm, List TestResult )

    -- Corners only
    , aa : Maybe ( Algorithm, List TestResult )
    , ab : Maybe ( Algorithm, List TestResult )
    , e : Maybe ( Algorithm, List TestResult )

    -- Edges And Corners
    , f : Maybe ( Algorithm, List TestResult )
    , ga : Maybe ( Algorithm, List TestResult )
    , gb : Maybe ( Algorithm, List TestResult )
    , gc : Maybe ( Algorithm, List TestResult )
    , gd : Maybe ( Algorithm, List TestResult )
    , ja : Maybe ( Algorithm, List TestResult )
    , jb : Maybe ( Algorithm, List TestResult )
    , na : Maybe ( Algorithm, List TestResult )
    , nb : Maybe ( Algorithm, List TestResult )
    , ra : Maybe ( Algorithm, List TestResult )
    , rb : Maybe ( Algorithm, List TestResult )
    , t : Maybe ( Algorithm, List TestResult )
    , v : Maybe ( Algorithm, List TestResult )
    , y : Maybe ( Algorithm, List TestResult )
    }


{-| The result of a test
-}
type TestResult
    = Correct
        { timestamp : Time.Posix
        , preAUF : AUF
        , postAUF : AUF
        , resultInMilliseconds : Int
        }
    | Wrong
        { timestamp : Time.Posix
        , preAUF : AUF
        , postAUF : AUF
        }


{-| The preAUF for a given test result
-}
testResultPreAUF : TestResult -> AUF
testResultPreAUF result =
    case result of
        Correct { preAUF } ->
            preAUF

        Wrong { preAUF } ->
            preAUF


{-| The postAUF for a given test result
-}
testResultPostAUF : TestResult -> AUF
testResultPostAUF result =
    case result of
        Correct { postAUF } ->
            postAUF

        Wrong { postAUF } ->
            postAUF


{-| Get the timestamp of a given test result
-}
testTimestamp : TestResult -> Time.Posix
testTimestamp testResult =
    case testResult of
        Correct { timestamp } ->
            timestamp

        Wrong { timestamp } ->
            timestamp


{-| A completely new user
-}
new : User
new =
    User
        { targetParameters = Nothing, pllData = emptyPLLData }
        Cube.Advanced.defaultTheme


emptyPLLData : PLLData
emptyPLLData =
    { h = Nothing
    , ua = Nothing
    , ub = Nothing
    , z = Nothing
    , aa = Nothing
    , ab = Nothing
    , e = Nothing
    , f = Nothing
    , ga = Nothing
    , gb = Nothing
    , gc = Nothing
    , gd = Nothing
    , ja = Nothing
    , jb = Nothing
    , na = Nothing
    , nb = Nothing
    , ra = Nothing
    , rb = Nothing
    , t = Nothing
    , v = Nothing
    , y = Nothing
    }



-- GETTERS AND MODIFIERS


{-| The users customized cube theme
-}
cubeTheme : User -> Cube.Advanced.CubeTheme
cubeTheme (User _ theme) =
    theme


{-| Whether the user has already chosen an algorithm for this pll
-}
hasChosenPLLAlgorithmFor : PLL -> User -> Bool
hasChosenPLLAlgorithmFor pll user =
    getPLLAlgorithm pll user
        |> Maybe.map (always True)
        |> Maybe.withDefault False


hasAttemptedPLLPreAUF : PLL -> AUF -> User -> Bool
hasAttemptedPLLPreAUF pll auf user =
    user
        |> getPLLData
        |> getPLLResults pll
        |> Maybe.withDefault []
        |> List.map testResultPreAUF
        |> List.member auf


hasAttemptedPLLPostAUF : PLL -> AUF -> User -> Bool
hasAttemptedPLLPostAUF pll auf user =
    user
        |> getPLLData
        |> getPLLResults pll
        |> Maybe.withDefault []
        |> List.map testResultPostAUF
        |> List.member auf


{-| Whether this test case should be considered new for the user.
This usually means either the PLL is being seen for the first time,
or the recognition angle or final AUF is being seen for the first time
-}
pllTestCaseIsNewForUser : ( AUF, PLL, AUF ) -> User -> Bool
pllTestCaseIsNewForUser ( preAUF, pll, postAUF ) user =
    not (hasAttemptedPLLPreAUF pll preAUF user)
        -- We consider the no AUF postAUF redundant as it's simply not making a move
        || (postAUF /= AUF.None && not (hasAttemptedPLLPostAUF pll postAUF user))


{-| If the user has attempted the specific pll
-}
hasAttemptedPLL : PLL -> User -> Bool
hasAttemptedPLL pll user =
    user
        |> getPLLData
        |> getPLLResults pll
        |> Maybe.withDefault []
        |> (List.isEmpty >> not)


{-| If the user has attempted any PLL yet
-}
hasAttemptedAnyPLLTestCase : User -> Bool
hasAttemptedAnyPLLTestCase user =
    PLL.all
        |> List.Nonempty.toList
        |> List.any (\pll -> hasAttemptedPLL pll user)


{-| Get the algorithm the user uses for this PLL
-}
getPLLAlgorithm : PLL -> User -> Maybe Algorithm
getPLLAlgorithm pll user =
    getPLLAlgorithm_ pll (getPLLData user)


{-| Change the algorithm the user uses for this PLL
-}
changePLLAlgorithm : PLL -> Algorithm -> User -> User
changePLLAlgorithm pll algorithm user =
    let
        newPLLData =
            setPLLAlgorithm pll algorithm (getPLLData user)
    in
    setPLLData newPLLData user


{-| Get the target parameters the user has for PLL cases.
Notice that you get values even if the user has not set their parameters
yet. This is a design decision to avoid complexity with maybe types
in places where they shouldn't really be, so we just give the default values
if the user hasn't chosen them yet. However, still note that the user should
be prompted to choose these values if they haven't yet.
-}
getPLLTargetParameters : User -> PLLTargetParameters
getPLLTargetParameters =
    getInternalPLLTargetParameters
        >> Maybe.withDefault { recognitionTimeInSeconds = 2, tps = 4 }


{-| Update the target parameters the user has for PLL cases
-}
changePLLTargetParameters : { targetRecognitionTimeInSeconds : Float, targetTps : Float } -> User -> User
changePLLTargetParameters { targetRecognitionTimeInSeconds, targetTps } =
    setInternalPLLTargetParameters
        (Just
            { recognitionTimeInSeconds = targetRecognitionTimeInSeconds
            , tps = targetTps
            }
        )


{-| Returns true if the user has previously selected their target parameters
-}
hasChosenPLLTargetParameters : User -> Bool
hasChosenPLLTargetParameters =
    getInternalPLLTargetParameters >> (/=) Nothing


{-| Describes the statistics we compute on a pll.

**AllRecentAttemptsSucceeded**: In this case we can compute proper statistics for it

**HasRecentDNF**: This makes stats like averages impossible

**CaseNotAttemptedYet**: Which means we obviously can't compute advanced statistics for it

-}
type CaseStatistics
    = AllRecentAttemptsSucceeded
        { lastThreeAverageMs : Float
        , lastThreeAverageTPS : Float
        , pll : PLL
        , lastTimeTested : Time.Posix
        }
    | HasRecentDNF PLL
    | CaseNotAttemptedYet PLL


{-| Get statistics for the users PLL progress
-}
pllStatistics :
    User
    -> List CaseStatistics
pllStatistics user =
    PLL.all
        |> List.Nonempty.toList
        |> List.map
            (\pll ->
                getSpecificPLLData pll (getPLLData user)
                    |> Maybe.andThen
                        (\( algorithm, resultsList ) ->
                            resultsList
                                |> List.Nonempty.fromList
                                |> Maybe.map
                                    (\nonEmptyResults ->
                                        ( ( nonEmptyResults, algorithm )
                                        , pll
                                        )
                                    )
                        )
                    |> Result.fromMaybe (CaseNotAttemptedYet pll)
            )
        |> List.map
            (Result.map <|
                Tuple.mapFirst
                    (\results ->
                        ( results
                            |> Tuple.first
                            |> List.Nonempty.head
                            |> testTimestamp
                        , computeAveragesOfLastThree results
                        )
                    )
            )
        |> List.map
            (Result.map <|
                \( ( lastTimeTested, maybeAverages ), pll ) ->
                    maybeAverages
                        |> Maybe.map
                            (\{ timeMs, tps } ->
                                AllRecentAttemptsSucceeded
                                    { lastThreeAverageMs = timeMs
                                    , lastThreeAverageTPS = tps
                                    , pll = pll
                                    , lastTimeTested = lastTimeTested
                                    }
                            )
                        |> Maybe.withDefault (HasRecentDNF pll)
            )
        |> List.map
            (\result ->
                case result of
                    Ok x ->
                        x

                    Err x ->
                        x
            )


computeAveragesOfLastThree : ( List.Nonempty.Nonempty TestResult, Algorithm ) -> Maybe { timeMs : Float, tps : Float }
computeAveragesOfLastThree ( results, algorithm ) =
    results
        |> List.Nonempty.take 3
        |> List.Nonempty.map
            (\result ->
                case result of
                    Correct { resultInMilliseconds, preAUF, postAUF } ->
                        Just <|
                            ( resultInMilliseconds
                            , Algorithm.Extra.complexityAdjustedTPS
                                { milliseconds = resultInMilliseconds }
                                ( preAUF, postAUF )
                                algorithm
                            )

                    Wrong _ ->
                        Nothing
            )
        |> listOfMaybesToMaybeList
        |> Maybe.map List.Nonempty.unzip
        |> Maybe.map (\( timeMs, tps ) -> { timeMs = averageInts timeMs, tps = average tps })


{-| If there's a single Nothing it will be nothing, else a list of all
the elements encapsulated in a Just
-}
listOfMaybesToMaybeList : List.Nonempty.Nonempty (Maybe a) -> Maybe (List.Nonempty.Nonempty a)
listOfMaybesToMaybeList list =
    let
        seed =
            Maybe.map List.Nonempty.singleton (List.Nonempty.head list)
    in
    List.Nonempty.tail list
        |> List.Nonempty.fromList
        |> Maybe.map
            (List.Nonempty.foldl
                (\next ->
                    Maybe.andThen (\accumulator -> Maybe.map (\justNext -> List.Nonempty.cons justNext accumulator) next)
                )
                seed
            )
        |> Maybe.withDefault seed


averageInts : List.Nonempty.Nonempty Int -> Float
averageInts =
    List.Nonempty.map toFloat >> average


average : List.Nonempty.Nonempty Float -> Float
average list =
    (List.Nonempty.toList >> List.sum) list / toFloat (List.Nonempty.length list)


{-| Order the pll statistics by worst case first
-}
orderByWorstCaseFirst : List CaseStatistics -> List CaseStatistics
orderByWorstCaseFirst =
    List.sortWith
        (\a b ->
            case ( a, b ) of
                ( CaseNotAttemptedYet _, CaseNotAttemptedYet _ ) ->
                    EQ

                ( CaseNotAttemptedYet _, _ ) ->
                    GT

                ( _, CaseNotAttemptedYet _ ) ->
                    LT

                ( HasRecentDNF _, HasRecentDNF _ ) ->
                    EQ

                ( HasRecentDNF _, _ ) ->
                    LT

                ( _, HasRecentDNF _ ) ->
                    GT

                ( AllRecentAttemptsSucceeded argsA, AllRecentAttemptsSucceeded argsB ) ->
                    let
                        primaryComparison =
                            -- For TPS lower is worse
                            compare argsA.lastThreeAverageTPS argsB.lastThreeAverageTPS

                        secondaryComparison =
                            compare argsA.lastThreeAverageMs argsB.lastThreeAverageMs
                                -- For total time higher is worse so we invert order
                                |> invertOrder
                    in
                    if primaryComparison == EQ then
                        secondaryComparison

                    else
                        primaryComparison
        )


invertOrder : Order -> Order
invertOrder comp =
    case comp of
        EQ ->
            EQ

        LT ->
            GT

        GT ->
            LT


{-| The types of errors that can occur when recording a result.

**NoAlgorithmPickedYet**: Occurs if you try to record a test result for a PLL that has
yet to have an algorithm picked for it

-}
type RecordResultError
    = NoAlgorithmPickedYet


{-| Record a test result for a pll test. If it is the first time the user
attempts this PLL, you can only record it after an algorithm has been picked
for the PLL case
-}
recordPLLTestResult : PLL -> TestResult -> User -> Result RecordResultError User
recordPLLTestResult pll result user =
    let
        maybeNewPLLData =
            addPLLResult pll result (getPLLData user)
    in
    maybeNewPLLData
        |> Result.fromMaybe NoAlgorithmPickedYet
        |> Result.map (\newPLLData -> setPLLData newPLLData user)



-- SERIALIZATION
-- top level (de)serialization


{-| These should optimally never be changed unless deprecating the
feature. It will completely break backwards compatibility unless
managed in the code somehow
-}
serializationKeys :
    { version : String
    , usersCurrentPLLAlgorithms : String
    , usersPLLResults : String
    , usersPLLTargetParameters :
        { topLevelKey : String
        , recognitionTime : String
        , tps : String
        }
    , testResult :
        { correct : String
        , timestamp : String
        , preAUF : String
        , postAUF : String
        , resultInMilliseconds : String
        }
    }
serializationKeys =
    { version = "version"
    , usersCurrentPLLAlgorithms = "usersCurrentPLLAlgorithms"
    , usersPLLResults = "usersPLLResults"
    , usersPLLTargetParameters =
        { topLevelKey = "usersPLLTargetParameters"
        , recognitionTime = "recognitionTime"
        , tps = "tps"
        }
    , testResult =
        -- These are subkeys that will be used many places so more important these are short
        { correct = "a"
        , timestamp = "b"
        , preAUF = "c"
        , postAUF = "d"
        , resultInMilliseconds = "e"
        }
    }


serializationVersion : Int
serializationVersion =
    2


{-| Serialize the user for saving or sending somewhere
-}
serialize : User -> Json.Encode.Value
serialize user =
    Json.Encode.object
        [ ( serializationKeys.version
          , Json.Encode.int serializationVersion
          )
        , ( serializationKeys.usersCurrentPLLAlgorithms
          , serializePLLAlgorithms (getPLLData user)
          )
        , ( serializationKeys.usersPLLResults
          , serializePLLResults (getPLLData user)
          )
        , ( serializationKeys.usersPLLTargetParameters.topLevelKey
          , serializePLLTargetParameters (getInternalPLLTargetParameters user)
          )
        ]


{-| Read and deserialize a serialized user
-}
deserialize : Json.Decode.Value -> Result Json.Decode.Error User
deserialize =
    Json.Decode.decodeValue decoder


decoder : Json.Decode.Decoder User
decoder =
    Json.Decode.maybe
        (Json.Decode.field serializationKeys.version Json.Decode.int)
        |> Json.Decode.andThen decoderByVersion


decoderByVersion : Maybe Int -> Json.Decode.Decoder User
decoderByVersion maybeVersion =
    case maybeVersion of
        Nothing ->
            decoderv1

        Just 2 ->
            decoderv2

        Just version ->
            Json.Decode.fail <|
                "Trying to decode user data but version "
                    ++ String.fromInt version
                    ++ " is not supported"


decoderv2 : Json.Decode.Decoder User
decoderv2 =
    let
        pllAlgorithms =
            Json.Decode.field
                serializationKeys.usersCurrentPLLAlgorithms
                pllAlgorithmsDecoder

        pllResults =
            Json.Decode.field
                serializationKeys.usersPLLResults
                pllResultsDecoder

        pllTargetParameters =
            Json.Decode.field
                serializationKeys.usersPLLTargetParameters.topLevelKey
                pllTargetParametersDecoder
    in
    Json.Decode.succeed new
        |> Json.Decode.map2 setPLLData (pllDataDecoder pllAlgorithms pllResults)
        |> Json.Decode.map2
            setInternalPLLTargetParameters
            pllTargetParameters


decoderv1 : Json.Decode.Decoder User
decoderv1 =
    let
        pllAlgorithms =
            Json.Decode.field
                serializationKeys.usersCurrentPLLAlgorithms
                pllAlgorithmsDecoder

        pllResults =
            Json.Decode.field
                serializationKeys.usersPLLResults
                pllResultsDecoder
    in
    Json.Decode.succeed new
        |> Json.Decode.map2 setPLLData (pllDataDecoder pllAlgorithms pllResults)



-- pll algorithms (de)serialization


serializePLLAlgorithms : PLLData -> Json.Encode.Value
serializePLLAlgorithms pllData =
    let
        stringKeyValuePairs =
            PLL.all
                |> List.Nonempty.toList
                |> List.filterMap
                    (\pll ->
                        getPLLAlgorithm_ pll pllData
                            |> Maybe.map Algorithm.toString
                            |> Maybe.map (Tuple.pair <| PLL.getLetters pll)
                    )

        objectKeyValuePairs =
            stringKeyValuePairs
                |> List.map (Tuple.mapSecond Json.Encode.string)
    in
    Json.Encode.object objectKeyValuePairs


serializePLLResults : PLLData -> Json.Encode.Value
serializePLLResults pllData =
    let
        keyValuePairs =
            PLL.all
                |> List.Nonempty.toList
                |> List.filterMap
                    (\pll ->
                        getPLLResults pll pllData
                            |> Maybe.map (Json.Encode.list serializeTestResult)
                            |> Maybe.map (Tuple.pair <| PLL.getLetters pll)
                    )
    in
    Json.Encode.object keyValuePairs


serializeTestResult : TestResult -> Json.Encode.Value
serializeTestResult result =
    case result of
        Wrong data ->
            Json.Encode.object
                (buildBaseSerializedTestResultObject { correct = False } data)

        Correct ({ resultInMilliseconds } as data) ->
            Json.Encode.object
                (( serializationKeys.testResult.resultInMilliseconds
                 , Json.Encode.int resultInMilliseconds
                 )
                    :: buildBaseSerializedTestResultObject { correct = True } data
                )


buildBaseSerializedTestResultObject :
    { correct : Bool }
    ->
        { a
            | timestamp : Time.Posix
            , preAUF : AUF
            , postAUF : AUF
        }
    -> List ( String, Json.Encode.Value )
buildBaseSerializedTestResultObject { correct } { timestamp, preAUF, postAUF } =
    [ ( serializationKeys.testResult.correct
      , Json.Encode.bool correct
      )
    , ( serializationKeys.testResult.timestamp
      , Json.Encode.int (Time.posixToMillis timestamp)
      )
    , ( serializationKeys.testResult.preAUF
      , Json.Encode.string (AUF.toString preAUF)
      )
    , ( serializationKeys.testResult.postAUF
      , Json.Encode.string (AUF.toString postAUF)
      )
    ]


serializePLLTargetParameters : Maybe PLLTargetParameters -> Json.Encode.Value
serializePLLTargetParameters maybeTargetParameters =
    case maybeTargetParameters of
        Nothing ->
            Json.Encode.null

        Just targetParameters ->
            Json.Encode.object
                [ ( serializationKeys.usersPLLTargetParameters.recognitionTime
                  , Json.Encode.float targetParameters.recognitionTimeInSeconds
                  )
                , ( serializationKeys.usersPLLTargetParameters.tps
                  , Json.Encode.float targetParameters.tps
                  )
                ]


pllDataDecoder :
    Json.Decode.Decoder (Dict String Algorithm)
    -> Json.Decode.Decoder (Dict String (List TestResult))
    -> Json.Decode.Decoder PLLData
pllDataDecoder algorithmsDecoder resultsDecoder =
    Json.Decode.map2
        (\algorithms results ->
            PLL.all
                |> List.Nonempty.foldl
                    (\pll previousPLLData ->
                        let
                            maybeAlgorithm =
                                Dict.get (PLL.getLetters pll) algorithms

                            testResults =
                                Dict.get (PLL.getLetters pll) results
                                    |> Maybe.withDefault []

                            maybeUpdatedData =
                                Maybe.map (\x -> ( x, testResults )) maybeAlgorithm
                        in
                        maybeUpdatedData
                            |> Maybe.map
                                (\updatedData -> setSpecificPLLData pll updatedData previousPLLData)
                            |> Maybe.withDefault previousPLLData
                    )
                    emptyPLLData
        )
        algorithmsDecoder
        resultsDecoder
        |> Json.Decode.andThen
            (\data ->
                let
                    failures =
                        PLL.all
                            |> List.Nonempty.toList
                            |> List.filter
                                (\pll ->
                                    getPLLAlgorithm_ pll data
                                        |> Maybe.map
                                            (\algorithm -> not <| PLL.solvedBy algorithm pll)
                                        |> Maybe.withDefault False
                                )
                            |> List.map PLL.getLetters
                in
                if List.length failures > 0 then
                    Json.Decode.fail
                        ("Some algorithms did not solve the pll they were assigned to, those plls were: "
                            ++ String.join ", " failures
                        )

                else
                    Json.Decode.succeed data
            )


pllAlgorithmsDecoder : Json.Decode.Decoder (Dict String Algorithm)
pllAlgorithmsDecoder =
    Json.Decode.dict Json.Decode.string
        |> Json.Decode.andThen
            (Dict.foldl
                (\key value dictResultOrFailuresList ->
                    case Algorithm.fromString value of
                        Ok algorithm ->
                            dictResultOrFailuresList
                                |> Result.map (Dict.insert key algorithm)

                        Err error ->
                            let
                                errorString =
                                    key ++ ": " ++ Algorithm.debugFromStringError error
                            in
                            case dictResultOrFailuresList of
                                Ok _ ->
                                    Err [ errorString ]

                                Err failures ->
                                    Err <| errorString :: failures
                )
                (Ok Dict.empty)
                >> (\dictResultOrFailuresList ->
                        case dictResultOrFailuresList of
                            Ok dictResult ->
                                Json.Decode.succeed dictResult

                            Err failures ->
                                Json.Decode.fail
                                    ("Some pll algorithms were invalid. The errors are: "
                                        ++ String.join "; " failures
                                    )
                   )
            )


pllResultsDecoder : Json.Decode.Decoder (Dict String (List TestResult))
pllResultsDecoder =
    Json.Decode.dict (Json.Decode.list testResultDecoder)


testResultDecoder : Json.Decode.Decoder TestResult
testResultDecoder =
    Json.Decode.field serializationKeys.testResult.correct Json.Decode.bool
        |> Json.Decode.andThen
            (\correct ->
                let
                    timestamp =
                        Json.Decode.field serializationKeys.testResult.timestamp Json.Decode.int
                            |> Json.Decode.map Time.millisToPosix

                    preAUF =
                        Json.Decode.field serializationKeys.testResult.preAUF Json.Decode.string
                            |> Json.Decode.map AUF.fromString
                            |> Json.Decode.andThen
                                (Result.map Json.Decode.succeed
                                    >> Result.withDefault (Json.Decode.fail "invalid AUF string")
                                )

                    postAUF =
                        Json.Decode.field serializationKeys.testResult.postAUF Json.Decode.string
                            |> Json.Decode.map AUF.fromString
                            |> Json.Decode.andThen
                                (Result.map Json.Decode.succeed
                                    >> Result.withDefault (Json.Decode.fail "invalid AUF string")
                                )

                    resultInMilliseconds =
                        Json.Decode.field serializationKeys.testResult.resultInMilliseconds Json.Decode.int
                in
                if correct then
                    Json.Decode.map4
                        (\timestamp_ preAUF_ postAUF_ resultInMilliseconds_ ->
                            Correct
                                { timestamp = timestamp_
                                , preAUF = preAUF_
                                , postAUF = postAUF_
                                , resultInMilliseconds = resultInMilliseconds_
                                }
                        )
                        timestamp
                        preAUF
                        postAUF
                        resultInMilliseconds

                else
                    Json.Decode.map3
                        (\timestamp_ preAUF_ postAUF_ ->
                            Wrong
                                { timestamp = timestamp_
                                , preAUF = preAUF_
                                , postAUF = postAUF_
                                }
                        )
                        timestamp
                        preAUF
                        postAUF
            )


pllTargetParametersDecoder : Json.Decode.Decoder (Maybe PLLTargetParameters)
pllTargetParametersDecoder =
    Json.Decode.nullable <|
        Json.Decode.map2
            (\recognitionTime tps ->
                { recognitionTimeInSeconds = recognitionTime
                , tps = tps
                }
            )
            (Json.Decode.field
                serializationKeys.usersPLLTargetParameters.recognitionTime
                Json.Decode.float
            )
            (Json.Decode.field
                serializationKeys.usersPLLTargetParameters.tps
                Json.Decode.float
            )



-- BOILERPLATE


getPLLAlgorithm_ : PLL -> PLLData -> Maybe Algorithm
getPLLAlgorithm_ pll data =
    Maybe.map Tuple.first (getSpecificPLLData pll data)


getPLLResults : PLL -> PLLData -> Maybe (List TestResult)
getPLLResults pll data =
    Maybe.map Tuple.second (getSpecificPLLData pll data)


getSpecificPLLData : PLL -> PLLData -> Maybe ( Algorithm, List TestResult )
getSpecificPLLData pll data =
    case pll of
        PLL.H ->
            data.h

        PLL.Ua ->
            data.ua

        PLL.Ub ->
            data.ub

        PLL.Z ->
            data.z

        PLL.Aa ->
            data.aa

        PLL.Ab ->
            data.ab

        PLL.E ->
            data.e

        PLL.F ->
            data.f

        PLL.Ga ->
            data.ga

        PLL.Gb ->
            data.gb

        PLL.Gc ->
            data.gc

        PLL.Gd ->
            data.gd

        PLL.Ja ->
            data.ja

        PLL.Jb ->
            data.jb

        PLL.Na ->
            data.na

        PLL.Nb ->
            data.nb

        PLL.Ra ->
            data.ra

        PLL.Rb ->
            data.rb

        PLL.T ->
            data.t

        PLL.V ->
            data.v

        PLL.Y ->
            data.y


setPLLAlgorithm :
    PLL
    -> Algorithm
    -> PLLData
    -> PLLData
setPLLAlgorithm pll newAlgorithm data =
    let
        newData =
            getSpecificPLLData pll data
                |> Maybe.map (Tuple.mapFirst (always newAlgorithm))
                |> Maybe.withDefault ( newAlgorithm, [] )
    in
    setSpecificPLLData pll newData data


addPLLResult : PLL -> TestResult -> PLLData -> Maybe PLLData
addPLLResult pll result data =
    let
        newData =
            getSpecificPLLData pll data
                |> (Maybe.map <|
                        Tuple.mapSecond <|
                            (::) result
                   )
    in
    newData
        |> Maybe.map (\justNewData -> setSpecificPLLData pll justNewData data)


setSpecificPLLData : PLL -> ( Algorithm, List TestResult ) -> PLLData -> PLLData
setSpecificPLLData pll newData data =
    case pll of
        PLL.H ->
            { data | h = Just newData }

        PLL.Ua ->
            { data | ua = Just newData }

        PLL.Ub ->
            { data | ub = Just newData }

        PLL.Z ->
            { data | z = Just newData }

        PLL.Aa ->
            { data | aa = Just newData }

        PLL.Ab ->
            { data | ab = Just newData }

        PLL.E ->
            { data | e = Just newData }

        PLL.F ->
            { data | f = Just newData }

        PLL.Ga ->
            { data | ga = Just newData }

        PLL.Gb ->
            { data | gb = Just newData }

        PLL.Gc ->
            { data | gc = Just newData }

        PLL.Gd ->
            { data | gd = Just newData }

        PLL.Ja ->
            { data | ja = Just newData }

        PLL.Jb ->
            { data | jb = Just newData }

        PLL.Na ->
            { data | na = Just newData }

        PLL.Nb ->
            { data | nb = Just newData }

        PLL.Ra ->
            { data | ra = Just newData }

        PLL.Rb ->
            { data | rb = Just newData }

        PLL.T ->
            { data | t = Just newData }

        PLL.V ->
            { data | v = Just newData }

        PLL.Y ->
            { data | y = Just newData }


getPLLTrainerData : User -> PLLTrainerData
getPLLTrainerData (User pllTrainerData _) =
    pllTrainerData


setPLLTrainerData : PLLTrainerData -> User -> User
setPLLTrainerData newPLLTrainerData (User _ theme) =
    User newPLLTrainerData theme


getInternalPLLTargetParameters : User -> Maybe PLLTargetParameters
getInternalPLLTargetParameters =
    getPLLTrainerData >> .targetParameters


setInternalPLLTargetParameters : Maybe PLLTargetParameters -> User -> User
setInternalPLLTargetParameters newTargetParameters user =
    let
        prevTrainerData =
            getPLLTrainerData user
    in
    setPLLTrainerData { prevTrainerData | targetParameters = newTargetParameters } user


getPLLData : User -> PLLData
getPLLData =
    getPLLTrainerData >> .pllData


setPLLData : PLLData -> User -> User
setPLLData newPLLData user =
    let
        prevTrainerData =
            getPLLTrainerData user
    in
    setPLLTrainerData { prevTrainerData | pllData = newPLLData } user
