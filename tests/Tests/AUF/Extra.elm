module Tests.AUF.Extra exposing (detectAUFsTests)

import AUF exposing (AUF)
import AUF.Extra
import Algorithm
import Cube
import Expect
import Fuzz
import Fuzz.Extra
import PLL
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
                        Algorithm.append
                            algorithm
                            (Algorithm.fromTurnList
                                -- An slice turn cannot be fixed by any AUF ever
                                [ Algorithm.Turn Algorithm.E Algorithm.Halfway Algorithm.Clockwise
                                ]
                            )
                in
                AUF.Extra.detectAUFs { toMatchTo = definitelyNotMatchingAlgorithm, toDetectFor = algorithm }
                    |> Expect.equal (Err AUF.Extra.NoAUFsMakeThemMatch)
        , fuzzWith { runs = 10 }
            (Fuzz.tuple3
                ( Fuzz.oneOf <| List.map Fuzz.constant [ PLL.H, PLL.Z, PLL.Na, PLL.Nb ]
                , Fuzz.Extra.auf
                , Fuzz.Extra.auf
                )
            )
            "the optimal AUF combination is chosen for symmetrical cases"
          <|
            \( pll, preAUF, postAUF ) ->
                let
                    pllAlgorithm =
                        PLL.getAlgorithm PLL.referenceAlgorithms pll
                in
                AUF.Extra.detectAUFs
                    { toMatchTo =
                        Algorithm.append (AUF.toAlgorithm preAUF) <|
                            Algorithm.append pllAlgorithm <|
                                AUF.toAlgorithm postAUF
                    , toDetectFor = pllAlgorithm
                    }
                    |> Result.map
                        (Expect.all
                            [ -- Ensure we are always at least giving a variant with less moves
                              countAUFTurns >> Expect.atMost (countAUFTurns ( preAUF, postAUF ))
                            ]
                        )
                    |> Result.withDefault (Expect.fail "was an err")
        ]


countAUFTurns : ( AUF, AUF ) -> Float
countAUFTurns ( preAUF, postAUF ) =
    countSingleAUFTurns preAUF + countSingleAUFTurns postAUF


countSingleAUFTurns : AUF -> Float
countSingleAUFTurns auf =
    case auf of
        AUF.None ->
            0

        -- Just anything between 1 and 1.5 really will do the trick for this usecase
        AUF.Halfway ->
            1.2

        _ ->
            1
