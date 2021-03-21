module VerifyExamples.AlgorithmRepository.ReferencePlls3 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec3 : Test.Test
spec3 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"F2 U (R' L) F2 (R L') U F2\"\n    --> Ok referencePlls.ub" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "F2 U (R' L) F2 (R L') U F2"
                )
                (
                Ok referencePlls.ub
                )