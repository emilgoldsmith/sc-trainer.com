module Utils.NonEmptyList exposing (NonEmptyList(..), combineAll, concatMap, map, singleton, toList)


type NonEmptyList a
    = NonEmptyList a (List a)


singleton : a -> NonEmptyList a
singleton element =
    NonEmptyList element []


toList : NonEmptyList a -> List a
toList (NonEmptyList x xs) =
    x :: xs


concatMap : (a -> NonEmptyList b) -> NonEmptyList a -> NonEmptyList b
concatMap f (NonEmptyList x xs) =
    let
        (NonEmptyList newHead startOfTail) =
            f x

        mappedTail =
            List.concatMap (f >> toList) xs
    in
    NonEmptyList newHead (startOfTail ++ mappedTail)


map : (a -> b) -> NonEmptyList a -> NonEmptyList b
map f (NonEmptyList x xs) =
    NonEmptyList (f x) (List.map f xs)


combineAll : (a -> a -> a) -> NonEmptyList a -> a
combineAll f (NonEmptyList x xs) =
    List.foldl f x xs
