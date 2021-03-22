module Expect.Extra exposing (equalListMembers, equalNonEmptyListMembers)

import Expect
import Utils.NonEmptyList as NonEmptyList


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


equalNonEmptyListMembers : NonEmptyList.NonEmptyList a -> NonEmptyList.NonEmptyList a -> Expect.Expectation
equalNonEmptyListMembers (NonEmptyList.NonEmptyList expectedHead expectedTail) (NonEmptyList.NonEmptyList actualHead actualTail) =
    if expectedHead /= actualHead then
        Expect.fail <|
            "Heads of non empty lists were not equal\n"
                ++ "\n"
                ++ "Expected: "
                ++ Debug.toString expectedHead
                ++ "\n\n"
                ++ "But received: "
                ++ Debug.toString actualHead

    else
        equalListMembers expectedTail actualTail
