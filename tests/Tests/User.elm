module Tests.User exposing (helperTests, serializationTests)

import AUF exposing (AUF)
import Algorithm
import Expect
import Fuzz
import Fuzz.Extra
import Json.Decode
import Json.Encode
import PLL
import Test exposing (..)
import Time
import User


helperTests : Test
helperTests =
    describe "helpers"
        [ describe "hasAttemptedAPLLTestCase"
            [ test "should return false for a new user" <|
                \_ ->
                    User.new
                        |> User.hasAttemptedAPLLTestCase
                        |> Expect.false "a new user has not attempted a pll test case"
            , fuzz Fuzz.Extra.pll "should return false for a user that only picked algorithms but didn't yet attempt a test case" <|
                \pll ->
                    User.new
                        |> User.changePLLAlgorithm pll Algorithm.empty
                        |> User.hasAttemptedAPLLTestCase
                        |> Expect.false "user only picked algorithms didn't attempt a case yet"
            , fuzz Fuzz.Extra.pll "should return true when there is a recorded test for a pll" <|
                \pll ->
                    User.new
                        |> User.changePLLAlgorithm pll Algorithm.empty
                        |> User.recordPLLTestResult
                            pll
                            (wrongResult ( AUF.Halfway, AUF.CounterClockwise ))
                        |> Result.map User.hasAttemptedAPLLTestCase
                        |> Expect.equal (Ok True)
            ]
        , describe "pllStatistics"
            [ test "passes simple test case with 4 attempts" <|
                \_ ->
                    let
                        algorithm =
                            PLL.getAlgorithm PLL.referenceAlgorithms PLL.Aa
                    in
                    User.new
                        |> User.changePLLAlgorithm
                            PLL.Aa
                            algorithm
                        |> User.recordPLLTestResult
                            PLL.Aa
                            (correctResult 500 ( AUF.Clockwise, AUF.None ))
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Aa
                                (correctResult 2000 ( AUF.None, AUF.Clockwise ))
                            )
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Aa
                                (correctResult 6000 ( AUF.None, AUF.None ))
                            )
                        -- We add a fourth one here to ensure only the three most recent tests are averaged
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Aa
                                (correctResult 1000 ( AUF.Halfway, AUF.CounterClockwise ))
                            )
                        |> Result.map User.pllStatistics
                        |> Result.withDefault []
                        -- To remove all the cases not attempted
                        |> User.orderByWorstCaseFirst
                        |> List.take 1
                        |> Expect.equal
                            [ User.AllRecentAttemptsSucceeded
                                { lastThreeAverageMs = 3000
                                , lastThreeAverageTPS =
                                    let
                                        length =
                                            toFloat (List.length <| Algorithm.toTurnList algorithm)

                                        -- The additions are the extra moves from the AUFs, and the
                                        -- denominator is the result time from above divided by 1000 to
                                        -- convert it to seconds
                                        first =
                                            (length + 1) / 2

                                        second =
                                            length / 6

                                        third =
                                            (length + 2) / 1
                                    in
                                    (first + second + third) / 3
                                , pll = PLL.Aa
                                , lastTimeTested = placeholderTestTimestamp
                                }
                            ]
            , test "passes a test with a failure in it" <|
                \_ ->
                    User.new
                        |> User.changePLLAlgorithm
                            PLL.Aa
                            (PLL.getAlgorithm PLL.referenceAlgorithms PLL.Aa)
                        |> User.recordPLLTestResult
                            PLL.Aa
                            (wrongResult ( AUF.Clockwise, AUF.Halfway ))
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Aa
                                (correctResult 2000 ( AUF.CounterClockwise, AUF.None ))
                            )
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Aa
                                (correctResult 2000 ( AUF.None, AUF.Halfway ))
                            )
                        |> Result.map User.pllStatistics
                        |> Result.withDefault []
                        -- To remove all the cases with no attempts on them
                        |> User.orderByWorstCaseFirst
                        |> List.take 1
                        |> Expect.equal
                            [ User.HasRecentDNF PLL.Aa ]
            , test "orders cases correctly" <|
                \_ ->
                    User.new
                        |> User.changePLLAlgorithm
                            PLL.Ab
                            (PLL.getAlgorithm PLL.referenceAlgorithms PLL.Ab)
                        |> User.changePLLAlgorithm
                            PLL.Na
                            (PLL.getAlgorithm PLL.referenceAlgorithms PLL.Na)
                        |> User.changePLLAlgorithm
                            PLL.Nb
                            (PLL.getAlgorithm PLL.referenceAlgorithms PLL.Nb)
                        |> User.recordPLLTestResult
                            PLL.Na
                            (correctResult 2200 ( AUF.None, AUF.None ))
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Ab
                                (correctResult 2000 ( AUF.None, AUF.None ))
                            )
                        |> Result.andThen
                            (User.recordPLLTestResult
                                PLL.Nb
                                (wrongResult ( AUF.None, AUF.None ))
                            )
                        |> Result.map User.pllStatistics
                        |> Result.withDefault []
                        |> User.orderByWorstCaseFirst
                        |> List.map
                            (\statistics ->
                                case statistics of
                                    User.AllRecentAttemptsSucceeded { pll } ->
                                        { encounteredBefore = True, learned = True, pll = pll }

                                    User.HasRecentDNF pll ->
                                        { encounteredBefore = True, learned = False, pll = pll }

                                    User.CaseNotAttemptedYet pll ->
                                        { encounteredBefore = False, learned = False, pll = pll }
                            )
                        -- We take 3 as the rest of the list should just be cases not attempted before
                        |> List.take 3
                        |> Expect.equal
                            [ { learned = False, encounteredBefore = True, pll = PLL.Nb }

                            -- We have Ab before Na here because we expect the ordering
                            -- to be based on TPS and even though Na is slower than Ab
                            -- it is a much shorter algorithm so the skill level seems to be
                            -- higher for Na than it is for Ab
                            , { learned = True, encounteredBefore = True, pll = PLL.Ab }
                            , { learned = True, encounteredBefore = True, pll = PLL.Na }
                            ]
            ]
        ]


correctResult : Int -> ( AUF, AUF ) -> User.TestResult
correctResult resultInMilliseconds ( preAUF, postAUF ) =
    User.Correct
        { timestamp = placeholderTestTimestamp
        , preAUF = preAUF
        , postAUF = postAUF
        , resultInMilliseconds = resultInMilliseconds
        }


wrongResult : ( AUF, AUF ) -> User.TestResult
wrongResult ( preAUF, postAUF ) =
    User.Wrong
        { timestamp = placeholderTestTimestamp
        , preAUF = preAUF
        , postAUF = postAUF
        }


placeholderTestTimestamp : Time.Posix
placeholderTestTimestamp =
    Time.millisToPosix 0


serializationTests : Test
serializationTests =
    describe "serialization"
        [ fuzz Fuzz.Extra.user "serializing a user followed by deserializing produces the original user" <|
            \user ->
                user
                    |> User.serialize
                    |> User.deserialize
                    |> Expect.equal (Ok user)
        , test "deserializing null fails" <|
            \_ ->
                User.deserialize Json.Encode.null
                    |> Expect.err
        , fuzz Fuzz.string "deserializing a random string fails" <|
            \string ->
                User.deserialize (Json.Encode.string string)
                    |> Expect.err
        , describe "Ensure Backwards Compatibility"
            [ test "it still works for the first format" <|
                \_ ->
                    let
                        fixture =
                            Result.withDefault Json.Encode.null <|
                                Json.Decode.decodeString Json.Decode.value "{\"usersCurrentPLLAlgorithms\":{\"H\":\"R2 U2 R U2 R2 U2 R2 U2 R U2 R2\",\"Ua\":\"F2 U' L R' F2 L' R U' F2\",\"Ub\":\"F2 U R' L F2 R L' U F2\",\"Z\":\"R B' R' B F R' F B' R' B R F2\",\"Aa\":\"R' F R' B2 R F' R' B2 R2\",\"Ab\":\"R B' R F2 R' B R F2 R2\",\"E\":\"D R' D2 F' D L D' F D2 R D' F' L' F\",\"F\":\"L F R' F' L' F' D2 B' L' B D2 F' R F2\",\"Ga\":\"F2' D R' U R' U' R D' F2 L' U L\",\"Gb\":\"R' U' R B2 D L' U L U' L D' B2\",\"Gc\":\"R2' D' F U' F U F' D R2 B U' B'\",\"Gd\":\"R U R' F2 D' L U' L' U L' D F2\",\"Ja\":\"B2 R' U' R B2 L' D L' D' L2\",\"Jb\":\"B2 L U L' B2 R D' R D R2\",\"Na\":\"L U' R U2 L' U R' L U' R U2 L' U R'\",\"Nb\":\"R' U L' U2 R U' L R' U L' U2 R U' L\",\"Ra\":\"F2 R' F' U' F' U F R F' U2 F U2 F'\",\"Rb\":\"R2 F R U R U' R' F' R U2 R' U2 R\",\"T\":\"F2 D R2 U' R2 F2 D' L2 U L2\",\"V\":\"R' U R' U' B' R' B2 U' B' U B' R B R\",\"Y\":\"F2 D R2 U R2 D' R' U' R F2 R' U R\"},\"usersPLLResults\":{\"H\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ua\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ub\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Z\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Aa\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ab\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"E\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"F\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ga\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Gb\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Gc\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Gd\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ja\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Jb\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Na\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Nb\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Ra\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Rb\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"T\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"V\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}],\"Y\":[{\"e\":832,\"a\":true,\"b\":123456,\"c\":\"U2\",\"d\":\"U'\"},{\"e\":1500,\"a\":true,\"b\":123456,\"c\":\"\",\"d\":\"U\"}]}}"
                    in
                    User.deserialize fixture
                        |> Expect.all
                            [ Expect.ok
                            , Result.withDefault User.new
                                >> User.hasChosenPLLAlgorithmFor PLL.H
                                >> Expect.true "an H perm should have been chosen"
                            ]

            -- , test "Produce a backwards compatibility fixture" <|
            --     \_ ->
            --         let
            --             userFixture =
            --                 List.Nonempty.foldl
            --                     (\pll user ->
            --                         let
            --                             withAlgorithmsChosen =
            --                                 User.changePLLAlgorithm
            --                                     pll
            --                                     (PLL.getAlgorithm PLL.referenceAlgorithms pll)
            --                                     user
            --                         in
            --                         withAlgorithmsChosen
            --                             |> User.recordPLLTestResult
            --                                 pll
            --                                 (User.Correct
            --                                     { timestamp = Time.millisToPosix 123456
            --                                     , preAUF = AUF.None
            --                                     , postAUF = AUF.Clockwise
            --                                     , resultInMilliseconds = 1500
            --                                     }
            --                                 )
            --                             |> Result.andThen
            --                                 (User.recordPLLTestResult
            --                                     pll
            --                                     (User.Correct
            --                                         { timestamp = Time.millisToPosix 123456
            --                                         , preAUF = AUF.Halfway
            --                                         , postAUF = AUF.CounterClockwise
            --                                         , resultInMilliseconds = 832
            --                                         }
            --                                     )
            --                                 )
            --                             |> Result.withDefault withAlgorithmsChosen
            --                     )
            --                     User.new
            --                     PLL.all
            --             justForLogging =
            --                 Debug.log "JSON Fixture" (Json.Encode.encode 0 <| User.serialize userFixture)
            --         in
            --         Expect.pass
            ]
        ]
