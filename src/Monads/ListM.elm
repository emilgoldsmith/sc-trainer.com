module Monads.ListM exposing (ListM, applicative, fromList, return, toList)


type ListM a
    = ListM (List a)


return : a -> ListM a
return x =
    ListM [ x ]


applicative : ListM a -> ListM (a -> b) -> ListM b
applicative (ListM list) (ListM functions) =
    ListM (List.concatMap (\fn -> List.map fn list) functions)


toList : ListM a -> List a
toList (ListM list) =
    list


fromList : List a -> ListM a
fromList =
    ListM
