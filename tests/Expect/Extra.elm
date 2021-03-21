module Expect.Extra exposing (equalListMembers)

import Expect


equalListMembers : List a -> List a -> Expect.Expectation
equalListMembers expected actual =
    let
        extraElements =
            List.filter (\x -> not <| List.member x expected) actual

        missingElements =
            List.filter (\x -> not <| List.member x actual) expected
    in
    if missingElements == [] && extraElements == [] then
        Expect.pass

    else
        Expect.fail <|
            "Lists don't have equal members\n"
                ++ "\n"
                ++ "The list had these extra elements:\n"
                ++ "\n"
                ++ Debug.toString extraElements
                ++ "\n\n"
                ++ "The list was missing these elements:\n"
                ++ "\n"
                ++ Debug.toString missingElements
