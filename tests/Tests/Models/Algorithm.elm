module Tests.Models.Algorithm exposing (algorithmFuzzer, appendTests, fromStringTests, inverseAlgTests, turnDirectionFuzzer, turnFuzzer, turnableFuzzer)

{-| This represents an Algorithm, which is an ordered sequence of moves to be applied
to a cube. Enjoy!
-}

import Expect
import Fuzz
import Models.Algorithm as Algorithm exposing (Algorithm, allTurnables)
import Test exposing (..)


fromStringTests : Test
fromStringTests =
    describe "fromString"
        [ fuzz validAlgorithmString "successfully parses valid algorithm strings" <|
            Algorithm.fromString
                >> Expect.ok
        , fuzz2 algorithmFuzzer turnSeparator "a rendered algorithm is correctly retrieved" <|
            \alg separator ->
                renderAlgorithm alg separator
                    |> Algorithm.fromString
                    |> Expect.equal (Ok alg)
        , test "handles differing whitespace separation between turns" <|
            \_ ->
                Algorithm.fromString "U U  U\tU   U  \t U    \t    U"
                    |> Expect.ok
        , todo "Confidence check that a simple example maps to what we would expect"
        , fuzz obviouslyInvalidAlgorithmString "errors on invalid algorithms" <|
            Algorithm.fromString
                >> Expect.err
        , test "errors on empty string as in the real world an algorithm always has turns" <|
            \_ ->
                Algorithm.fromString "" |> Expect.err
        , test "errors on 2 apostrophes in a row" <|
            \_ ->
                Algorithm.fromString "U''" |> Expect.err
        , test "errors on space between the turnable and the apostrophe" <|
            \_ ->
                Algorithm.fromString "U '" |> Expect.err
        , test "errors on apostrophe before turn length" <|
            \_ ->
                Algorithm.fromString "U'2" |> Expect.err
        , test "errors on space between turnable and turn length" <|
            \_ ->
                Algorithm.fromString "U 2" |> Expect.err
        , test "errors on turn length 4" <|
            \_ ->
                Algorithm.fromString "U4" |> Expect.err
        , test "errors on turn length specified twice" <|
            \_ ->
                Algorithm.fromString "U22'" |> Expect.err
        , test "errors on newline between turns" <|
            \_ ->
                Algorithm.fromString "U2'\nU" |> Expect.err
        , todo "The turnable specified twice should be tested for a good error message"
        ]


inverseAlgTests : Test
inverseAlgTests =
    describe "inverseAlg"
        [ fuzz algorithmFuzzer "the inverse of the inverse should be the original algorithm" <|
            \alg ->
                alg
                    |> Algorithm.inverse
                    |> Algorithm.inverse
                    |> Expect.equal alg
        , fuzz2 algorithmFuzzer algorithmFuzzer "the inverse of an algorithm equals splitting the alg in two, inversing each part and swapping their order" <|
            \part1 part2 ->
                Algorithm.appendTo (Algorithm.inverse part2) (Algorithm.inverse part1)
                    |> Expect.equal (Algorithm.inverse (Algorithm.appendTo part1 part2))
        , test "correctly inverses simple example" <|
            \_ ->
                let
                    alg =
                        Algorithm.build
                            [ Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.Clockwise
                            , Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.CounterClockwise
                            ]

                    inversedAlg =
                        Algorithm.build
                            [ Algorithm.Turn Algorithm.R Algorithm.OneQuarter Algorithm.Clockwise
                            , Algorithm.Turn Algorithm.U Algorithm.OneQuarter Algorithm.CounterClockwise
                            ]
                in
                alg |> Algorithm.inverse |> Expect.equal inversedAlg
        ]


appendTests : Test
appendTests =
    describe "append"
        [ fuzz2 turnFuzzer turnFuzzer "Appending two algorithms each consisting of a turn equals an algorithm with those two turns in a row" <|
            \turn1 turn2 ->
                Algorithm.appendTo (Algorithm.build [ turn1 ]) (Algorithm.build [ turn2 ])
                    |> Expect.equal (Algorithm.build [ turn1, turn2 ])
        ]


obviouslyInvalidAlgorithmString : Fuzz.Fuzzer String
obviouslyInvalidAlgorithmString =
    let
        notFaceOrSlice c =
            not <| List.member c (List.map renderTurnable allTurnables)

        removeFaceAndSliceChars =
            String.filter notFaceOrSlice
    in
    Fuzz.map removeFaceAndSliceChars Fuzz.string


validAlgorithmString : Fuzz.Fuzzer String
validAlgorithmString =
    Fuzz.map2 renderAlgorithm algorithmFuzzer turnSeparator


algorithmFuzzer : Fuzz.Fuzzer Algorithm
algorithmFuzzer =
    let
        nonEmptyTurnList =
            Fuzz.map2 (::) turnFuzzer <| Fuzz.list turnFuzzer
    in
    Fuzz.map Algorithm.build nonEmptyTurnList


renderAlgorithm : Algorithm -> String -> String
renderAlgorithm alg separator =
    let
        renderedTurnList =
            Algorithm.extractInternals >> List.map renderTurn <| alg
    in
    String.join separator renderedTurnList


turnSeparator : Fuzz.Fuzzer String
turnSeparator =
    Fuzz.oneOf
        [ Fuzz.constant ""
        , Fuzz.constant " "
        , Fuzz.constant "  "
        , Fuzz.constant "   "
        , Fuzz.constant "\t"
        ]


turnFuzzer : Fuzz.Fuzzer Algorithm.Turn
turnFuzzer =
    Fuzz.map3 Algorithm.Turn turnableFuzzer turnLength turnDirectionFuzzer


renderTurn : Algorithm.Turn -> String
renderTurn (Algorithm.Turn x length direction) =
    -- For double/triple turns clockwise we format it as U2' / U3' as these are used in some
    -- algorithms for explanations of fingertricks, also notice it's not U'2 or U'3. This
    -- decision was made based on "use in the wild" specifically the Youtuber Jperm's use.
    String.fromChar (renderTurnable x) ++ renderLength length ++ renderDirection direction


turnableFuzzer : Fuzz.Fuzzer Algorithm.Turnable
turnableFuzzer =
    Fuzz.oneOf <| List.map Fuzz.constant Algorithm.allTurnables


renderTurnable : Algorithm.Turnable -> Char
renderTurnable x =
    case x of
        Algorithm.U ->
            'U'

        Algorithm.D ->
            'D'

        Algorithm.L ->
            'L'

        Algorithm.R ->
            'R'

        Algorithm.F ->
            'F'

        Algorithm.B ->
            'B'

        Algorithm.M ->
            'M'

        Algorithm.S ->
            'S'

        Algorithm.E ->
            'E'


turnLength : Fuzz.Fuzzer Algorithm.TurnLength
turnLength =
    Fuzz.oneOf <| List.map Fuzz.constant Algorithm.allTurnLengths


renderLength : Algorithm.TurnLength -> String
renderLength length =
    case length of
        Algorithm.OneQuarter ->
            ""

        Algorithm.Halfway ->
            "2"

        Algorithm.ThreeQuarters ->
            "3"


turnDirectionFuzzer : Fuzz.Fuzzer Algorithm.TurnDirection
turnDirectionFuzzer =
    Fuzz.oneOf <| List.map Fuzz.constant Algorithm.allTurnDirections


renderDirection : Algorithm.TurnDirection -> String
renderDirection dir =
    case dir of
        Algorithm.Clockwise ->
            ""

        Algorithm.CounterClockwise ->
            "'"
