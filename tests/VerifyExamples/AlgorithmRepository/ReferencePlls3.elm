module VerifyExamples.AlgorithmRepository.ReferencePlls3 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec3 : Test.Test
spec3 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"R2' D' F U' F U F' D R2 B U' B'\"\n    --> Ok referencePlls.gc" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "R2' D' F U' F U F' D R2 B U' B'"
                )
                (
                Ok referencePlls.gc
                )