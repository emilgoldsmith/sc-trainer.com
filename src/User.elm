module User exposing (RecordResultError(..), TestResult(..), User, changePLLAlgorithm, deserialize, hasAttemptedAPLLTestCase, hasChosenPLLAlgorithmFor, new, pllStatistics, recordPLLTestResult, serialize)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Dict exposing (Dict)
import Json.Decode
import Json.Encode
import List.Nonempty
import PLL exposing (PLL)
import Time


type User
    = User PLLUserData


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


new : User
new =
    User emptyPLLData


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


hasChosenPLLAlgorithmFor : PLL -> User -> Bool
hasChosenPLLAlgorithmFor pll (User pllData) =
    getPLLAlgorithm pll pllData
        |> Maybe.map (always True)
        |> Maybe.withDefault False


hasAttemptedAPLLTestCase : User -> Bool
hasAttemptedAPLLTestCase (User pllData) =
    PLL.all
        |> List.Nonempty.toList
        |> List.filterMap (\pll -> getPLLResults pll pllData)
        |> List.any (List.isEmpty >> not)


changePLLAlgorithm : PLL -> Algorithm -> User -> User
changePLLAlgorithm pll algorithm (User pllData) =
    let
        newPLLData =
            setPLLAlgorithm pll algorithm pllData
    in
    User newPLLData


pllStatistics : User -> List Float
pllStatistics (User pllData) =
    PLL.all
        |> List.Nonempty.toList
        |> List.filterMap (\pll -> getPLLResults pll pllData)
        |> List.map
            (List.filterMap
                (\result ->
                    case result of
                        Correct { resultInMilliseconds } ->
                            Just resultInMilliseconds

                        Wrong _ ->
                            Nothing
                )
            )
        |> List.map (List.map toFloat)
        |> List.map average


average : List Float -> Float
average list =
    if List.isEmpty list then
        0

    else
        List.sum list / toFloat (List.length list)


type RecordResultError
    = NoAlgorithmPickedYet


recordPLLTestResult : PLL -> TestResult -> User -> Result RecordResultError User
recordPLLTestResult pll result (User pllData) =
    let
        newPLLData =
            addPLLResult pll result pllData
    in
    newPLLData
        |> Result.fromMaybe NoAlgorithmPickedYet
        |> Result.map User



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


serialize : User -> Json.Encode.Value
serialize (User pllData) =
    Json.Encode.object
        [ ( serializationKeys.usersCurrentPLLAlgorithms
          , serializePLLAlgorithms pllData
          )
        , ( serializationKeys.usersPLLResults
          , serializePLLResults pllData
          )
        ]


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
            Json.Decode.map (Maybe.withDefault Dict.empty) <|
                Json.Decode.maybe <|
                    Json.Decode.field
                        serializationKeys.usersPLLResults
                        pllResultsDecoder
    in
    pllUserDataDecoder pllAlgorithms pllResults
        |> Json.Decode.map User



-- pll algorithms (de)serialization


serializePLLAlgorithms : PLLUserData -> Json.Encode.Value
serializePLLAlgorithms pllData =
    let
        stringKeyValuePairs =
            PLL.all
                |> List.Nonempty.toList
                |> List.filterMap
                    (\pll ->
                        getPLLAlgorithm pll pllData
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
                    (\pll pllData ->
                        let
                            maybeAlgorithm =
                                Dict.get (PLL.getLetters pll) algorithms

                            testResults =
                                Dict.get (PLL.getLetters pll) results
                                    |> Maybe.withDefault []

                            maybePLLData =
                                Maybe.map (\x -> ( x, testResults )) maybeAlgorithm
                        in
                        Maybe.map
                            (\newData -> setPLLData pll newData pllData)
                            maybePLLData
                            |> Maybe.withDefault pllData
                    )
                    emptyPLLData
        )


pllAlgorithmsDecoder : Json.Decode.Decoder (Dict String Algorithm)
pllAlgorithmsDecoder =
    Json.Decode.dict Json.Decode.string
        |> Json.Decode.map (dictFilterMap (Algorithm.fromString >> Result.toMaybe))


dictFilterMap : (a -> Maybe b) -> Dict comparable a -> Dict comparable b
dictFilterMap fn =
    Dict.foldl
        (\key value newDict ->
            case fn value of
                Nothing ->
                    newDict

                Just x ->
                    Dict.insert key x newDict
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
                        (\a b c d ->
                            Correct
                                { timestamp = a
                                , preAUF = b
                                , postAUF = c
                                , resultInMilliseconds = d
                                }
                        )
                        timestamp
                        preAUF
                        postAUF
                        resultInMilliseconds

                else
                    Json.Decode.map3
                        (\a b c ->
                            Wrong
                                { timestamp = a
                                , preAUF = b
                                , postAUF = c
                                }
                        )
                        timestamp
                        preAUF
                        postAUF
            )



-- BOILERPLATE


getPLLAlgorithm : PLL -> PLLUserData -> Maybe Algorithm
getPLLAlgorithm pll data =
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
setPLLData pll newAlgorithm algorithms =
    case pll of
        PLL.H ->
            { algorithms | h = Just newAlgorithm }

        PLL.Ua ->
            { algorithms | ua = Just newAlgorithm }

        PLL.Ub ->
            { algorithms | ub = Just newAlgorithm }

        PLL.Z ->
            { algorithms | z = Just newAlgorithm }

        PLL.Aa ->
            { algorithms | aa = Just newAlgorithm }

        PLL.Ab ->
            { algorithms | ab = Just newAlgorithm }

        PLL.E ->
            { algorithms | e = Just newAlgorithm }

        PLL.F ->
            { algorithms | f = Just newAlgorithm }

        PLL.Ga ->
            { algorithms | ga = Just newAlgorithm }

        PLL.Gb ->
            { algorithms | gb = Just newAlgorithm }

        PLL.Gc ->
            { algorithms | gc = Just newAlgorithm }

        PLL.Gd ->
            { algorithms | gd = Just newAlgorithm }

        PLL.Ja ->
            { algorithms | ja = Just newAlgorithm }

        PLL.Jb ->
            { algorithms | jb = Just newAlgorithm }

        PLL.Na ->
            { algorithms | na = Just newAlgorithm }

        PLL.Nb ->
            { algorithms | nb = Just newAlgorithm }

        PLL.Ra ->
            { algorithms | ra = Just newAlgorithm }

        PLL.Rb ->
            { algorithms | rb = Just newAlgorithm }

        PLL.T ->
            { algorithms | t = Just newAlgorithm }

        PLL.V ->
            { algorithms | v = Just newAlgorithm }

        PLL.Y ->
            { algorithms | y = Just newAlgorithm }
