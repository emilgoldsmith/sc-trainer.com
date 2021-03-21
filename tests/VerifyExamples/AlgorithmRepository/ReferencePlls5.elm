module VerifyExamples.AlgorithmRepository.ReferencePlls5 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec5 : Test.Test
spec5 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"F2 U (R' L) F2 (R L') U F2\"\n    --> Ok referencePlls.ub" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "F2 U (R' L) F2 (R L') U F2"
                )
                (
                Ok referencePlls.ub
                )