module List.Nonempty.Extra exposing (allMinimums, find, findMap, lift2, lift3)

import List.Extra
import List.Nonempty
import Random


find : (a -> Bool) -> List.Nonempty.Nonempty a -> Maybe a
find fn list =
    List.Extra.find fn (List.Nonempty.toList list)


findMap : (a -> Maybe b) -> List.Nonempty.Nonempty a -> Maybe b
findMap fn list =
    List.Extra.findMap fn (List.Nonempty.toList list)


lift2 :
    (a -> b -> c)
    -> List.Nonempty.Nonempty a
    -> List.Nonempty.Nonempty b
    -> List.Nonempty.Nonempty c
lift2 f la lb =
    la
        |> List.Nonempty.concatMap
            (\a -> lb |> List.Nonempty.map (f a))


lift3 :
    (a -> b -> c -> d)
    -> List.Nonempty.Nonempty a
    -> List.Nonempty.Nonempty b
    -> List.Nonempty.Nonempty c
    -> List.Nonempty.Nonempty d
lift3 f la lb lc =
    la
        |> List.Nonempty.concatMap
            (\a ->
                lb
                    |> List.Nonempty.concatMap
                        (\b ->
                            lc
                                |> List.Nonempty.map (f a b)
                        )
            )


allMinimums : (a -> a -> Order) -> List.Nonempty.Nonempty a -> List.Nonempty.Nonempty a
allMinimums cmp (List.Nonempty.Nonempty head tail) =
    List.foldl
        (\next cur ->
            case cmp next (List.Nonempty.head cur) of
                LT ->
                    List.Nonempty.singleton next

                EQ ->
                    List.Nonempty.cons next cur

                GT ->
                    cur
        )
        (List.Nonempty.singleton head)
        tail
