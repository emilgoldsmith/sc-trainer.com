module VerifyExamples.Models.Cube.CornerLocations0 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import Models.Cube exposing (..)







spec0 : Test.Test
spec0 =
    Test.test "#cornerLocations: \n\n    List.length cornerLocations\n    --> 8" <|
        \() ->
            Expect.equal
                (
                List.length cornerLocations
                )
                (
                8
                )