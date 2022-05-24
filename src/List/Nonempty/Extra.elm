module List.Nonempty.Extra exposing (lift2, lift3)

import List.Nonempty


lift2 :
    (a -> b -> c)
    -> List.Nonempty.Nonempty a
    -> List.Nonempty.Nonempty b
    -> List.Nonempty.Nonempty c
lift2 f la lb =
    la
        |> List.Nonempty.concatMap
            (\a -> lb |> List.Nonempty.map (\b -> f a b))


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
                                |> List.Nonempty.map (\c -> f a b c)
                        )
            )
