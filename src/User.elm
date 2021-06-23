module User exposing (User, changePLLAlgorithm, deserialize, hasChosenPLLAlgorithmFor, new, serialize)

import Algorithm exposing (Algorithm)
import Dict
import Json.Decode
import Json.Encode
import List.Nonempty
import PLL exposing (PLL)


type User
    = User UsersCurrentPLLAlgorithms


type alias UsersCurrentPLLAlgorithms =
    { -- Edges only
      h : Maybe Algorithm
    , ua : Maybe Algorithm
    , ub : Maybe Algorithm
    , z : Maybe Algorithm

    -- Corners only
    , aa : Maybe Algorithm
    , ab : Maybe Algorithm
    , e : Maybe Algorithm

    -- Edges And Corners
    , f : Maybe Algorithm
    , ga : Maybe Algorithm
    , gb : Maybe Algorithm
    , gc : Maybe Algorithm
    , gd : Maybe Algorithm
    , ja : Maybe Algorithm
    , jb : Maybe Algorithm
    , na : Maybe Algorithm
    , nb : Maybe Algorithm
    , ra : Maybe Algorithm
    , rb : Maybe Algorithm
    , t : Maybe Algorithm
    , v : Maybe Algorithm
    , y : Maybe Algorithm
    }


new : User
new =
    User emptyPLLAlgorithms


emptyPLLAlgorithms : UsersCurrentPLLAlgorithms
emptyPLLAlgorithms =
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
hasChosenPLLAlgorithmFor pll (User pllAlgorithms) =
    getPLLAlgorithm pllAlgorithms pll
        |> Maybe.map (always True)
        |> Maybe.withDefault False


changePLLAlgorithm : PLL -> Algorithm -> User -> User
changePLLAlgorithm pll algorithm (User pllAlgorithms) =
    let
        newPllAlgorithms =
            setPLLAlgorithm pllAlgorithms pll algorithm
    in
    User newPllAlgorithms



-- SERIALIZATION
-- top level (de)serialization


{-| These should optimally never be changed unless deprecating the
feature. It will completely break backwards compatibility unless
managed in the code somehow
-}
serializationKeys : { usersCurrentPLLAlgorithms : String }
serializationKeys =
    { usersCurrentPLLAlgorithms = "usersCurrentPLLAlgorithms"
    }


serialize : User -> Json.Encode.Value
serialize (User pllAlgorithms) =
    Json.Encode.object
        [ ( serializationKeys.usersCurrentPLLAlgorithms
          , serializePllAlgorithms pllAlgorithms
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
    in
    Json.Decode.map User pllAlgorithms



-- pll algorithms (de)serialization


serializePllAlgorithms : UsersCurrentPLLAlgorithms -> Json.Encode.Value
serializePllAlgorithms pllAlgorithms =
    let
        stringKeyValuePairs =
            PLL.all
                |> List.Nonempty.toList
                |> List.filterMap
                    (\pll ->
                        getPLLAlgorithm pllAlgorithms pll
                            |> Maybe.map Algorithm.toString
                            |> Maybe.map (Tuple.pair <| PLL.getLetters pll)
                    )

        objectKeyValuePairs =
            stringKeyValuePairs
                |> List.map (Tuple.mapSecond Json.Encode.string)
    in
    Json.Encode.object objectKeyValuePairs


pllAlgorithmsDecoder : Json.Decode.Decoder UsersCurrentPLLAlgorithms
pllAlgorithmsDecoder =
    Json.Decode.dict Json.Decode.string
        |> Json.Decode.map
            (\dict ->
                PLL.all
                    |> List.Nonempty.foldl
                        (\pll algorithms ->
                            let
                                maybeAlgorithmString =
                                    Dict.get (PLL.getLetters pll) dict

                                maybeAlgorithmResult =
                                    Maybe.map Algorithm.fromString maybeAlgorithmString

                                maybeAlgorithm =
                                    Maybe.andThen Result.toMaybe maybeAlgorithmResult
                            in
                            Maybe.map (setPLLAlgorithm algorithms pll) maybeAlgorithm
                                |> Maybe.withDefault algorithms
                        )
                        emptyPLLAlgorithms
            )



-- BOILERPLATE


getPLLAlgorithm : UsersCurrentPLLAlgorithms -> PLL -> Maybe Algorithm
getPLLAlgorithm algorithms pll =
    case pll of
        PLL.H ->
            algorithms.h

        PLL.Ua ->
            algorithms.ua

        PLL.Ub ->
            algorithms.ub

        PLL.Z ->
            algorithms.z

        PLL.Aa ->
            algorithms.aa

        PLL.Ab ->
            algorithms.ab

        PLL.E ->
            algorithms.e

        PLL.F ->
            algorithms.f

        PLL.Ga ->
            algorithms.ga

        PLL.Gb ->
            algorithms.gb

        PLL.Gc ->
            algorithms.gc

        PLL.Gd ->
            algorithms.gd

        PLL.Ja ->
            algorithms.ja

        PLL.Jb ->
            algorithms.jb

        PLL.Na ->
            algorithms.na

        PLL.Nb ->
            algorithms.nb

        PLL.Ra ->
            algorithms.ra

        PLL.Rb ->
            algorithms.rb

        PLL.T ->
            algorithms.t

        PLL.V ->
            algorithms.v

        PLL.Y ->
            algorithms.y


setPLLAlgorithm :
    UsersCurrentPLLAlgorithms
    -> PLL
    -> Algorithm
    -> UsersCurrentPLLAlgorithms
setPLLAlgorithm algorithms pll newAlgorithm =
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
