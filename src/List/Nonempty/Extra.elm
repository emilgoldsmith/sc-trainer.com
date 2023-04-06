module List.Nonempty.Extra exposing (find, lift2, lift3)

import List.Extra
import List.Nonempty


find : (a -> Bool) -> List.Nonempty.Nonempty a -> Maybe a
find fn list =
    List.Extra.find fn (List.Nonempty.toList list)


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
