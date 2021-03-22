module VerifyExamples.AlgorithmRepository.ReferencePlls5 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec5 : Test.Test
spec5 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"B2 R' U' R B2 L' D L' D' L2\"\n    --> Ok referencePlls.ja" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "B2 R' U' R B2 L' D L' D' L2"
                )
                (
                Ok referencePlls.ja
                )