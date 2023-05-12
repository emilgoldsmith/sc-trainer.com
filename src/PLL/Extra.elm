module PLL.Extra exposing (PreferredAUFsError(..), getPreferredEquivalentAUFs)

import AUF exposing (AUF)
import List.Nonempty
import List.Nonempty.Extra
import PLL exposing (PLL)
import User exposing (PLLAUFPreferences)


type PreferredAUFsError
    = InvalidPreferences PLLAUFPreferences ( AUF, PLL, AUF )


getPreferredEquivalentAUFs : PLLAUFPreferences -> ( AUF, PLL, AUF ) -> Result PreferredAUFsError ( AUF, AUF )
getPreferredEquivalentAUFs preferences testCase =
    let
        optimalOptions =
            Debug.log "testCase" testCase
                |> PLL.getAllEquivalentAUFs
                |> List.Nonempty.Extra.allMinimums
                    (\a b ->
                        -- Lower turn count is always the better option
                        compare (countAUFTurns a) (countAUFTurns b)
                    )
    in
    Debug.log "result" <|
        case optimalOptions of
            List.Nonempty.Nonempty onlyOption [] ->
                -- If only one optimal option we choose that one
                Ok onlyOption

            nonSingletonOptions ->
                -- Else we choose the preference
                Debug.log "preferences" preferences
                    |> User.getPLLAUFPreferencesList
                    |> List.Nonempty.Extra.find
                        (\pref ->
                            nonSingletonOptions
                                |> List.Nonempty.Extra.find (\option -> option == pref)
                                |> Maybe.map (always True)
                                |> Maybe.withDefault False
                        )
                    |> Result.fromMaybe (InvalidPreferences preferences testCase)


countAUFTurns : ( AUF, AUF ) -> Float
countAUFTurns ( preAUF, postAUF ) =
    countSingleAUFTurns preAUF + countSingleAUFTurns postAUF


countSingleAUFTurns : AUF -> Float
countSingleAUFTurns auf =
    case auf of
        AUF.None ->
            0

        -- Just anything between 1 and 1.5 really will do the trick for this usecase
        -- as it will never add a full 1 with two numbers added together but be more than a quarter turn
        AUF.Halfway ->
            1.2

        AUF.Clockwise ->
            1

        AUF.CounterClockwise ->
            1
