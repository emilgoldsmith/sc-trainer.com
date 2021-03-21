module VerifyExamples.AlgorithmRepository.ReferencePlls4 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec4 : Test.Test
spec4 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"L F R' F' L' F' D2 B' L' B D2 F' R F2\"\n    --> Ok referencePlls.f" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "L F R' F' L' F' D2 B' L' B D2 F' R F2"
                )
                (
                Ok referencePlls.f
                )