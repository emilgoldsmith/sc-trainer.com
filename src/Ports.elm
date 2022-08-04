port module Ports exposing (logError, onTESTONLYCurrentTestCaseRequested, onTESTONLYOverrideCubeDisplayAngle, onTESTONLYOverrideDisplayCubeAnnotations, onTESTONLYOverrideNextTestCase, onTESTONLYSetCubeSizeOverride, onTESTONLYSetPLLAlgorithm, onTESTONLYSetTestCase, tESTONLYEmitCurrentTestCase, updateStoredUser)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Cube
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty
import PLL exposing (PLL)
import PLLTrainer.TestCase exposing (TestCase)
import User exposing (User)



-- LOCAL STORAGE MANAGEMENT


port updateStoredUserPort : Json.Encode.Value -> Cmd msg


updateStoredUser : User -> Cmd msg
updateStoredUser =
    User.serialize >> updateStoredUserPort



-- ERROR HANDLING


port logError : String -> Cmd msg



-- TEST ONLY PORTS


port setPLLAlgorithmPort : ({ algorithm : String, pll : String } -> msg) -> Sub msg


onTESTONLYSetPLLAlgorithm : (( Result Json.Decode.Error PLL, Result Algorithm.FromStringError Algorithm ) -> msg) -> Sub msg
onTESTONLYSetPLLAlgorithm toMsg =
    setPLLAlgorithmPort
        (\{ algorithm, pll } ->
            ( Json.Decode.decodeString pllDecoder pll, Algorithm.fromString algorithm )
                |> toMsg
        )


port overrideDisplayCubeAnnotationsPort : (Maybe Bool -> msg) -> Sub msg


onTESTONLYOverrideDisplayCubeAnnotations : (Maybe Bool -> msg) -> Sub msg
onTESTONLYOverrideDisplayCubeAnnotations =
    overrideDisplayCubeAnnotationsPort


port overrideCubeDisplayAnglePort : (Maybe String -> msg) -> Sub msg


onTESTONLYOverrideCubeDisplayAngle : (Maybe Cube.DisplayAngle -> msg) -> Sub msg
onTESTONLYOverrideCubeDisplayAngle toMsg =
    overrideCubeDisplayAnglePort (parseDisplayAngle >> toMsg)


parseDisplayAngle : Maybe String -> Maybe Cube.DisplayAngle
parseDisplayAngle string =
    case Maybe.map String.toLower string of
        Just "ufr" ->
            Just Cube.ufrDisplayAngle

        Just "ubl" ->
            Just Cube.ublDisplayAngle

        Just "dbl" ->
            Just Cube.dblDisplayAngle

        _ ->
            Nothing


port sendMeCurrentTestCasePort : (Json.Decode.Value -> msg) -> Sub msg


onTESTONLYCurrentTestCaseRequested : msg -> Sub msg
onTESTONLYCurrentTestCaseRequested msg =
    sendMeCurrentTestCasePort (always msg)


port receiveCurrentTestCasePort : Json.Encode.Value -> Cmd msg


tESTONLYEmitCurrentTestCase : TestCase -> Cmd msg
tESTONLYEmitCurrentTestCase testCase =
    receiveCurrentTestCasePort <|
        Json.Encode.list Json.Encode.string <|
            [ PLLTrainer.TestCase.preAUF testCase
                |> AUF.toString
            , PLLTrainer.TestCase.pll testCase
                |> PLL.getLetters
            , PLLTrainer.TestCase.postAUF testCase
                |> AUF.toString
            ]


port setCubeSizeOverridePort : (Maybe Int -> msg) -> Sub msg


onTESTONLYSetCubeSizeOverride : (Maybe Int -> msg) -> Sub msg
onTESTONLYSetCubeSizeOverride =
    setCubeSizeOverridePort


port setCurrentTestCasePort : (Json.Decode.Value -> msg) -> Sub msg


onTESTONLYSetTestCase : (Result Json.Decode.Error TestCase -> msg) -> Sub msg
onTESTONLYSetTestCase toMsg =
    setCurrentTestCasePort (Json.Decode.decodeValue testCaseDecoder >> toMsg)


port overrideNextTestCasePort : (Json.Decode.Value -> msg) -> Sub msg


onTESTONLYOverrideNextTestCase : (Result Json.Decode.Error TestCase -> msg) -> Sub msg
onTESTONLYOverrideNextTestCase toMsg =
    overrideNextTestCasePort (Json.Decode.decodeValue testCaseDecoder >> toMsg)


testCaseDecoder : Json.Decode.Decoder TestCase
testCaseDecoder =
    Json.Decode.map3 PLLTrainer.TestCase.build
        (Json.Decode.index 0 aufDecoder)
        (Json.Decode.index 1 pllDecoder)
        (Json.Decode.index 2 aufDecoder)


aufDecoder : Json.Decode.Decoder AUF
aufDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\aufString ->
                case AUF.fromString aufString of
                    Ok auf ->
                        Json.Decode.succeed auf

                    Err errorMessage ->
                        Json.Decode.fail (AUF.debugFromStringError errorMessage)
            )


pllDecoder : Json.Decode.Decoder PLL
pllDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (stringToPll
                >> Maybe.map Json.Decode.succeed
                >> Maybe.withDefault (Json.Decode.fail "Not a valid PLL case")
            )


stringToPll : String -> Maybe PLL
stringToPll stringValue =
    PLL.all
        |> List.Nonempty.toList
        |> List.map (\pll -> ( pll, PLL.getLetters pll ))
        |> List.Extra.find (Tuple.second >> (==) stringValue)
        |> Maybe.map Tuple.first
