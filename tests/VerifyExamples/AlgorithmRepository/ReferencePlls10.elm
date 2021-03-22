module VerifyExamples.AlgorithmRepository.ReferencePlls10 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import AlgorithmRepository exposing (..)
import Models.Algorithm







spec10 : Test.Test
spec10 =
    Test.test "#referencePlls: \n\n    Models.Algorithm.fromString \"R B' R' B F R' F B' R' B R F2\"\n    --> Ok referencePlls.z" <|
        \() ->
            Expect.equal
                (
                Models.Algorithm.fromString "R B' R' B F R' F B' R' B R F2"
                )
                (
                Ok referencePlls.z
                )