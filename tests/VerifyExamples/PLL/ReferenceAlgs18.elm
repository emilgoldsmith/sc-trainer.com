module VerifyExamples.PLL.ReferenceAlgs18 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import PLL exposing (..)
import Algorithm







spec18 : Test.Test
spec18 =
    Test.test "#referenceAlgs: \n\n    Algorithm.fromString \"F2 U (R' L) F2 (R L') U F2\"\n    --> Ok referenceAlgs.ub" <|
        \() ->
            Expect.equal
                (
                Algorithm.fromString "F2 U (R' L) F2 (R L') U F2"
                )
                (
                Ok referenceAlgs.ub
                )