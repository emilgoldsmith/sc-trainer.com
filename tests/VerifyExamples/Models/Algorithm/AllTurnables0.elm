module VerifyExamples.Models.Algorithm.AllTurnables0 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import Models.Algorithm exposing (..)







spec0 : Test.Test
spec0 =
    Test.test "#allTurnables: \n\n    List.length allTurnables\n    --> 4" <|
        \() ->
            Expect.equal
                (
                List.length allTurnables
                )
                (
                4
                )