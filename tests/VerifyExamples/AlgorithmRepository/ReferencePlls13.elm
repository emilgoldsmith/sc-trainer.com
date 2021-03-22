module VerifyExamples.AlgorithmRepository.ReferencePlls13 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec13 : Test.Test
spec13 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"R' F R' B2 R F' R' B2 R2\"\n    --> Ok referencePlls.aa" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "R' F R' B2 R F' R' B2 R2"
                )
                (
                Ok referencePlls.aa
                )