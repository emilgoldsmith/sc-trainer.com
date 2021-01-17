module Tests.Models.Algorithm exposing (suite)

{-| This represents an Algorithm, which is an ordered sequence of moves to be applied
to a cube. Enjoy!
-}

import Expect
import Fuzz
import Models.Algorithm as Algorithm exposing (Algorithm)
import Test exposing (..)


suite : Test
suite =
    describe "Models.Algorithm"
        [ describe "fromString"
            [ fuzz validAlgorithmString "successfully parses valid algorithms" <|
                Algorithm.fromString
                    >> Expect.ok
            , fuzz obviouslyInvalidAlgorithmString "errors on invalid algorithms" <|
                Algorithm.fromString
                    >> Expect.err
            , test "errors on empty string as in the real world an algorithm always has turns" <|
                \_ ->
                    Algorithm.fromString "" |> Expect.err
            , todo "Do some specific cases with edge cases surrounding invalid algorithms"
            , todo "Assert that some valid algorithms map to the expected algorithm, including all the separate cases"
            , todo "Assert that it handles spaces and tabs in algorithm"
            , todo "Assert that it doesn't allow newlines"
            ]
        , describe "inverseAlg"
            [ -- [ fuzz validAlgorithmString "the inverse of the inverse should be the original algorithm" <|
              --     \turns ->
              --         turnsToAlg turns |> Result.map Algorithm.inverse |> Result.map Algorithm.inverse |> Expect.all [ Expect.ok, Expect.equal (turnsToAlg turns) ]
              -- , fuzz2 validAlgorithmString validAlgorithmString "the inverse of an algorithm equals splitting the alg in two, inversing each part and swapping their order" <|
              --     \part1 part2 ->
              --         let
              --             fullAlgorithm =
              --                 turnsToAlg <| part1 ++ part2
              --             alg1 =
              --                 turnsToAlg part1
              --             alg2 =
              --                 turnsToAlg part2
              --             inversedAlgorithm =
              --                 Result.map Algorithm.inverse fullAlgorithm
              --         in
              --         Result.map2 (++) (Result.map Algorithm.inverse alg2) (Result.map Algorithm.inverse alg1) |> Expect.all [ Expect.ok, Expect.equal inversedAlgorithm ]
              skip <|
                test "correctly inverses simple example" <|
                    \_ ->
                        let
                            alg =
                                Algorithm.fromString "UR'"

                            inversedAlg =
                                Algorithm.fromString "RU'"
                        in
                        alg |> Result.map Algorithm.inverse |> Expect.all [ Expect.ok, Expect.equal inversedAlg ]
            ]
        ]


turnsToAlg : List String -> Result String Algorithm
turnsToAlg =
    String.join "" >> Algorithm.fromString


obviouslyInvalidAlgorithmString : Fuzz.Fuzzer String
obviouslyInvalidAlgorithmString =
    let
        notFaceOrSlice c =
            List.member c facesAndSlices |> not

        removeFaceAndSliceChars =
            String.filter notFaceOrSlice
    in
    Fuzz.map removeFaceAndSliceChars Fuzz.string


validAlgorithmString : Fuzz.Fuzzer String
validAlgorithmString =
    let
        separatorAndTurns =
            Fuzz.tuple ( turnSeparator, nonEmptyTurnList )
    in
    Fuzz.map (\( separator, turns ) -> String.join separator turns) separatorAndTurns


turnSeparator : Fuzz.Fuzzer String
turnSeparator =
    Fuzz.oneOf
        [ Fuzz.constant ""

        -- , Fuzz.constant " "
        -- , Fuzz.constant "  "
        -- , Fuzz.constant "   "
        -- , Fuzz.constant "\t"
        ]


nonEmptyTurnList : Fuzz.Fuzzer (List String)
nonEmptyTurnList =
    Fuzz.map2 (::) turn <| Fuzz.list turn


turn : Fuzz.Fuzzer String
turn =
    -- For double/triple turns clockwise we format it as U2' / U3' as these are used in some
    -- algorithms for explanations of fingertricks, also notice it's not U'2 or U'3. This
    -- decision was made based on "use in the wild" specifically the Youtuber Jperm's use.
    Fuzz.map3 (\a b c -> a ++ b ++ c) turnable turnLength turnDirection


quarterTurn : Fuzz.Fuzzer String
quarterTurn =
    Fuzz.map2 (++) turnable turnDirection


turnable : Fuzz.Fuzzer String
turnable =
    Fuzz.oneOf <| List.map (String.fromChar >> Fuzz.constant) facesAndSlices


facesAndSlices : List Char
facesAndSlices =
    [ 'U' ]


turnLength : Fuzz.Fuzzer String
turnLength =
    Fuzz.oneOf
        [ Fuzz.constant ""
        , Fuzz.constant "2"
        , Fuzz.constant "3"
        ]


turnDirection : Fuzz.Fuzzer String
turnDirection =
    Fuzz.oneOf
        [ Fuzz.constant "" -- No prime = clockwise
        , Fuzz.constant "'" -- prime = counterclockwise
        ]
