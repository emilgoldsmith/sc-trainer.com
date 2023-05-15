module Tests.PLL.Extra exposing (getPreferredEquivalentAUFsTests)

import AUF exposing (AUF)
import Expect
import Fuzz
import Fuzz.Extra
import PLL
import PLL.Extra
import Test exposing (..)
import User


getPreferredEquivalentAUFsTests : Test
getPreferredEquivalentAUFsTests =
    describe "getPreferredEquivalentAUFs"
        [ fuzzWith { runs = 10, distribution = noDistribution }
            (Fuzz.triple
                (Fuzz.oneOf <| List.map Fuzz.constant [ PLL.H, PLL.Z, PLL.Na, PLL.Nb, PLL.E ])
                Fuzz.Extra.auf
                Fuzz.Extra.auf
            )
            "never chooses a pair that makes the total moves longer symmetrical cases"
          <|
            \( pll, preAUF, postAUF ) ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.defaultPLLAUFPreferences pll)
                    ( preAUF, pll, postAUF )
                    |> Result.map countAUFTurns
                    |> Result.withDefault 999999999999
                    |> Expect.atMost (countAUFTurns ( preAUF, postAUF ))
        , test "respects the preferences with several preferences listed and a non-identical AUF is being presented" <|
            \_ ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.tESTONLYBuildPLLAUFPreferences
                        ( ( AUF.Clockwise, AUF.CounterClockwise )
                        , ( AUF.None, AUF.Halfway )
                        , ( AUF.Clockwise, AUF.Halfway )
                        )
                    )
                    ( AUF.CounterClockwise, PLL.Z, AUF.Clockwise )
                    |> Expect.equal (Ok ( AUF.Clockwise, AUF.CounterClockwise ))
        , test "respects the preferences with the inverse of the previous case" <|
            \_ ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.tESTONLYBuildPLLAUFPreferences
                        ( ( AUF.CounterClockwise, AUF.Clockwise )
                        , ( AUF.None, AUF.Halfway )
                        , ( AUF.Clockwise, AUF.Halfway )
                        )
                    )
                    ( AUF.Clockwise, PLL.Z, AUF.CounterClockwise )
                    |> Expect.equal (Ok ( AUF.CounterClockwise, AUF.Clockwise ))
        , test "respects the preferences with several preferences listed and an identical AUF being presented" <|
            \_ ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.tESTONLYBuildPLLAUFPreferences
                        ( ( AUF.Clockwise, AUF.CounterClockwise )
                        , ( AUF.None, AUF.Halfway )
                        , ( AUF.Clockwise, AUF.Halfway )
                        )
                    )
                    ( AUF.Clockwise, PLL.Z, AUF.CounterClockwise )
                    |> Expect.equal (Ok ( AUF.Clockwise, AUF.CounterClockwise ))
        , test "respects the preferences with the inverse of the previous identifical AUF being presented case" <|
            \_ ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.tESTONLYBuildPLLAUFPreferences
                        ( ( AUF.CounterClockwise, AUF.Clockwise )
                        , ( AUF.None, AUF.Halfway )
                        , ( AUF.Clockwise, AUF.Halfway )
                        )
                    )
                    ( AUF.CounterClockwise, PLL.Z, AUF.Clockwise )
                    |> Expect.equal (Ok ( AUF.CounterClockwise, AUF.Clockwise ))
        , test "fails on invalid preferences with several optimal options" <|
            \_ ->
                PLL.Extra.getPreferredEquivalentAUFs
                    (User.tESTONLYBuildPLLAUFPreferences
                        ( ( AUF.CounterClockwise, AUF.Clockwise )
                        , ( AUF.Clockwise, AUF.Halfway )
                        , ( AUF.Clockwise, AUF.Halfway )
                        )
                    )
                    ( AUF.None, PLL.Z, AUF.Halfway )
                    |> Expect.err
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
