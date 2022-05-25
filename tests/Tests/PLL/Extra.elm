module Tests.PLL.Extra exposing (getPreferredEquivalentAUFsTests)

import AUF exposing (AUF)
import Expect
import Fuzz
import Fuzz.Extra
import PLL
import PLL.Extra
import Test exposing (..)


getPreferredEquivalentAUFsTests : Test
getPreferredEquivalentAUFsTests =
    describe "getPreferredEquivalentAUFs"
        [ fuzzWith { runs = 10 }
            (Fuzz.tuple3
                ( Fuzz.oneOf <| List.map Fuzz.constant [ PLL.H, PLL.Z, PLL.Na, PLL.Nb, PLL.E ]
                , Fuzz.Extra.auf
                , Fuzz.Extra.auf
                )
            )
            "never chooses a pair that makes the total moves longer symmetrical cases"
          <|
            \( pll, preAUF, postAUF ) ->
                PLL.Extra.getPreferredEquivalentAUFs ( preAUF, pll, postAUF )
                    |> countAUFTurns
                    |> Expect.atMost (countAUFTurns ( preAUF, postAUF ))
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
