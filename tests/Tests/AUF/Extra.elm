module Tests.AUF.Extra exposing (detectAUFsTests)

import AUF
import AUF.Extra
import Algorithm
import Cube
import Expect
import Fuzz
import Fuzz.Extra
import Test exposing (..)


detectAUFsTests : Test
detectAUFsTests =
    describe "detectAUFs"
        [ fuzzWith { runs = 5 } (Fuzz.tuple3 ( Fuzz.Extra.algorithm, Fuzz.Extra.algorithm, Fuzz.tuple ( Fuzz.Extra.auf, Fuzz.Extra.auf ) )) "correctly detects aufs on the same algorithm with an identity sequence appended to it" <|
            \( algorithm, algorithmForIdentity, aufs ) ->
                let
                    identitySequence =
                        Algorithm.append algorithmForIdentity (Algorithm.inverse algorithmForIdentity)

                    algorithmToMatch =
                        Algorithm.append algorithm identitySequence
                            |> AUF.addToAlgorithm aufs

                    detectedAUFsResult =
                        AUF.Extra.detectAUFs { toMatchTo = algorithmToMatch, toDetectFor = algorithm }

                    resultingAlgorithm =
                        detectedAUFsResult
                            |> Result.map
                                (\detectedAUFs ->
                                    algorithm
                                        |> AUF.addToAlgorithm detectedAUFs
                                )
                in
                resultingAlgorithm
                    |> Result.map (Cube.algorithmResultsAreEquivalent algorithmToMatch)
                    |> Result.map (Expect.true "The algorithm built using detect should be equivalent to the one we're matching")
                    |> Result.withDefault (Expect.fail "No possible AUFs detected when some should have been found")
        , fuzzWith { runs = 5 } Fuzz.Extra.algorithm "no matches are found for algorithms that are not equivalent no matter the AUF between them" <|
            \algorithm ->
                let
                    definitelyNotMatchingAlgorithm =
                        algorithm
                            |> Algorithm.append
                                (Algorithm.fromTurnList
                                    -- An F turn cannot be fixed by any AUF
                                    [ Algorithm.Turn Algorithm.F Algorithm.Halfway Algorithm.Clockwise
                                    ]
                                )
                in
                AUF.Extra.detectAUFs { toMatchTo = definitelyNotMatchingAlgorithm, toDetectFor = algorithm }
                    |> Expect.equal (Err AUF.Extra.NoAUFsMakeThemMatch)
        ]
