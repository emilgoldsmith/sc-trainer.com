module Tests.User exposing (serializationTests)

import Expect
import Fuzz
import Json.Encode
import Test exposing (..)
import User exposing (User)


serializationTests : Test
serializationTests =
    describe "serialization"
        [ fuzz userFuzzer "serializing a user followed by deserializing produces the original user" <|
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
        ]


userFuzzer : Fuzz.Fuzzer User
userFuzzer =
    Fuzz.constant User.new
