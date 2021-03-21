module VerifyExamples.AlgorithmRepository.ReferencePlls11 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec11 : Test.Test
spec11 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"R2 U2 R U2 R2 U2 R2 U2 R U2 R2\"\n    --> Ok referencePlls.h" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "R2 U2 R U2 R2 U2 R2 U2 R U2 R2"
                )
                (
                Ok referencePlls.h
                )