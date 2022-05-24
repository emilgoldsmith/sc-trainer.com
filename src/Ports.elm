port module Ports exposing (logError, onTESTONLYOverrideNextTestCase, onTESTONLYSetCubeSizeOverride, onTESTONLYSetExtraAlgToApplyToAllCubes, onTESTONLYSetTestCase, updateStoredUser)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
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


port setExtraAlgToApplyToAllCubesPort : (String -> msg) -> Sub msg


onTESTONLYSetExtraAlgToApplyToAllCubes : (Result Algorithm.FromStringError Algorithm -> msg) -> Sub msg
onTESTONLYSetExtraAlgToApplyToAllCubes toMsg =
    setExtraAlgToApplyToAllCubesPort (Algorithm.fromString >> toMsg)


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
