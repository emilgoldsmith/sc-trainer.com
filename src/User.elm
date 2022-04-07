module User exposing
    ( User
    , new
    , getPLLAlgorithm, changePLLAlgorithm, hasChosenPLLAlgorithmFor, hasAttemptedAPLLTestCase, cubeTheme
    , TestResult(..), RecordResultError(..), recordPLLTestResult
    , CaseStatistics(..), pllStatistics, orderByWorstCaseFirst
    , serialize, deserialize
    )

{-|


# Type

@docs User


# Constructors

@docs new


# Getters And Setters

@docs getPLLAlgorithm, changePLLAlgorithm, hasChosenPLLAlgorithmFor, hasAttemptedAPLLTestCase, cubeTheme


# Event Handling

@docs TestResult, RecordResultError, recordPLLTestResult


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
    = User PLLUserData Cube.Advanced.CubeTheme


type alias PLLUserData =
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


{-| A completely new user
-}
new : User
new =
    User emptyPLLData Cube.Advanced.defaultTheme


emptyPLLData : PLLUserData
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


{-| If the user has attempted any PLL yet
-}
hasAttemptedAPLLTestCase : User -> Bool
hasAttemptedAPLLTestCase user =
    PLL.all
        |> List.Nonempty.toList
        |> List.filterMap (\pll -> getPLLResults pll (getPLLUserData user))
        |> List.any (List.isEmpty >> not)


{-| Get the algorithm the user uses for this PLL
-}
getPLLAlgorithm : PLL -> User -> Maybe Algorithm
getPLLAlgorithm pll user =
    getPLLAlgorithm_ pll (getPLLUserData user)


{-| Change the algorithm the user uses for this PLL
-}
changePLLAlgorithm : PLL -> Algorithm -> User -> User
changePLLAlgorithm pll algorithm user =
    let
        newPLLData =
            setPLLAlgorithm pll algorithm (getPLLUserData user)
    in
    setPLLUserData newPLLData user


{-| Describes the statistics we compute on a pll.

**CaseLearnedStatistics**: If the last three attempts were successful
we can compute proper statistics for it

**CaseNotLearnedStatistics**: If there are at least

-}
type CaseStatistics
    = CaseLearnedStatistics
        { lastThreeAverageMs : Float
        , lastThreeAverageTPS : Float
        , pll : PLL
        }
    | CaseNotLearnedStatistics PLL


{-| Get statistics for the users PLL progress
-}
pllStatistics :
    User
    -> List CaseStatistics
pllStatistics user =
    PLL.all
        |> List.Nonempty.toList
        |> List.filterMap
            (\pll ->
                getPLLData pll (getPLLUserData user)
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
            )
        |> List.map (Tuple.mapFirst computeAveragesOfLastThree)
        |> List.map
            (\( maybeAverages, pll ) ->
                maybeAverages
                    |> Maybe.map
                        (\{ timeMs, tps } ->
                            CaseLearnedStatistics
                                { lastThreeAverageMs = timeMs
                                , lastThreeAverageTPS = tps
                                , pll = pll
                                }
                        )
                    |> Maybe.withDefault (CaseNotLearnedStatistics pll)
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
    List.Nonempty.foldl
        (\next ->
            Maybe.andThen (\accumulator -> Maybe.map (\justNext -> List.Nonempty.cons justNext accumulator) next)
        )
        (Maybe.map List.Nonempty.singleton (List.Nonempty.head list))
        list


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
                ( CaseNotLearnedStatistics _, CaseNotLearnedStatistics _ ) ->
                    EQ

                ( CaseNotLearnedStatistics _, _ ) ->
                    LT

                ( _, CaseNotLearnedStatistics _ ) ->
                    GT

                ( CaseLearnedStatistics argsA, CaseLearnedStatistics argsB ) ->
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
            addPLLResult pll result (getPLLUserData user)
    in
    maybeNewPLLData
        |> Result.fromMaybe NoAlgorithmPickedYet
        |> Result.map (\newPLLData -> setPLLUserData newPLLData user)



-- SERIALIZATION
-- top level (de)serialization


{-| These should optimally never be changed unless deprecating the
feature. It will completely break backwards compatibility unless
managed in the code somehow
-}
serializationKeys :
    { usersCurrentPLLAlgorithms : String
    , usersPLLResults : String
    , testResult :
        { correct : String
        , timestamp : String
        , preAUF : String
        , postAUF : String
        , resultInMilliseconds : String
        }
    }
serializationKeys =
    { usersCurrentPLLAlgorithms = "usersCurrentPLLAlgorithms"
    , usersPLLResults = "usersPLLResults"
    , testResult =
        -- These are subkeys that will be used many places so more important these are short
        { correct = "a"
        , timestamp = "b"
        , preAUF = "c"
        , postAUF = "d"
        , resultInMilliseconds = "e"
        }
    }


{-| Serialize the user for saving or sending somewhere
-}
serialize : User -> Json.Encode.Value
serialize user =
    Json.Encode.object
        [ ( serializationKeys.usersCurrentPLLAlgorithms
          , serializePLLAlgorithms (getPLLUserData user)
          )
        , ( serializationKeys.usersPLLResults
          , serializePLLResults (getPLLUserData user)
          )
        ]


{-| Read and deserialize a serialized user
-}
deserialize : Json.Decode.Value -> Result Json.Decode.Error User
deserialize =
    Json.Decode.decodeValue decoder


decoder : Json.Decode.Decoder User
decoder =
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
    pllUserDataDecoder pllAlgorithms pllResults
        |> Json.Decode.map (\pllUserData -> setPLLUserData pllUserData new)



-- pll algorithms (de)serialization


serializePLLAlgorithms : PLLUserData -> Json.Encode.Value
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


serializePLLResults : PLLUserData -> Json.Encode.Value
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


pllUserDataDecoder :
    Json.Decode.Decoder (Dict String Algorithm)
    -> Json.Decode.Decoder (Dict String (List TestResult))
    -> Json.Decode.Decoder PLLUserData
pllUserDataDecoder =
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
                        Maybe.map
                            (\updatedData -> setPLLData pll updatedData previousPLLData)
                            maybeUpdatedData
                            |> Maybe.withDefault previousPLLData
                    )
                    emptyPLLData
        )


pllAlgorithmsDecoder : Json.Decode.Decoder (Dict String Algorithm)
pllAlgorithmsDecoder =
    Json.Decode.dict Json.Decode.string
        -- TODO: Log an error here somehow instead of just silently swallowing invalid
        -- algorithms in local storage?
        |> Json.Decode.map (dictFilterMap (Algorithm.fromString >> Result.toMaybe))


dictFilterMap : (a -> Maybe b) -> Dict comparable a -> Dict comparable b
dictFilterMap fn =
    Dict.foldl
        (\key value curDict ->
            case fn value of
                Nothing ->
                    curDict

                Just x ->
                    Dict.insert key x curDict
        )
        Dict.empty


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



-- BOILERPLATE


getPLLAlgorithm_ : PLL -> PLLUserData -> Maybe Algorithm
getPLLAlgorithm_ pll data =
    Maybe.map Tuple.first (getPLLData pll data)


getPLLResults : PLL -> PLLUserData -> Maybe (List TestResult)
getPLLResults pll data =
    Maybe.map Tuple.second (getPLLData pll data)


getPLLData : PLL -> PLLUserData -> Maybe ( Algorithm, List TestResult )
getPLLData pll data =
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
    -> PLLUserData
    -> PLLUserData
setPLLAlgorithm pll newAlgorithm data =
    let
        newData =
            getPLLData pll data
                |> Maybe.map (Tuple.mapFirst (always newAlgorithm))
                |> Maybe.withDefault ( newAlgorithm, [] )
    in
    setPLLData pll newData data


addPLLResult : PLL -> TestResult -> PLLUserData -> Maybe PLLUserData
addPLLResult pll result data =
    let
        newData =
            getPLLData pll data
                |> (Maybe.map <|
                        Tuple.mapSecond <|
                            (::) result
                   )
    in
    newData
        |> Maybe.map (\justNewData -> setPLLData pll justNewData data)


setPLLData : PLL -> ( Algorithm, List TestResult ) -> PLLUserData -> PLLUserData
setPLLData pll newData data =
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


getPLLUserData : User -> PLLUserData
getPLLUserData (User pllUserData _) =
    pllUserData


setPLLUserData : PLLUserData -> User -> User
setPLLUserData newPLLUserData (User _ theme) =
    User newPLLUserData theme
