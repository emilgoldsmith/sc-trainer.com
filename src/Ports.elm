port module Ports exposing (logError, onTESTONLYSetExtraAlgToApplyToAllCubes, onTESTONLYSetTestCase, updateStoredUser)

import AUF exposing (AUF)
import Algorithm exposing (Algorithm)
import Json.Decode
import Json.Encode
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


port setCurrentTestCasePort : (Json.Decode.Value -> msg) -> Sub msg


onTESTONLYSetTestCase : (Result Json.Decode.Error TestCase -> msg) -> Sub msg
onTESTONLYSetTestCase toMsg =
    setCurrentTestCasePort (Json.Decode.decodeValue testCaseDecoder >> toMsg)


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
    let
        allPllLetters =
            List.Nonempty.map
                (\pll -> ( pll, PLL.getLetters pll ))
                PLL.all
                -- Make it a list so we can do a proper filter on it
                |> List.Nonempty.toList

        matches =
            List.filter (Tuple.second >> (==) stringValue) allPllLetters
    in
    case matches of
        -- No matches and we don't do anything
        [] ->
            Nothing

        -- There shouldn't ever be several matches but in case there
        -- are we just pick the first one
        ( pll, _ ) :: _ ->
            Just pll
