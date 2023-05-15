module List.Nonempty.Extra exposing (allMinimums, find)

import List.Extra
import List.Nonempty


find : (a -> Bool) -> List.Nonempty.Nonempty a -> Maybe a
find fn list =
    List.Extra.find fn (List.Nonempty.toList list)


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
