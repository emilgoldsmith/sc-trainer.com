module Utils.Enumerator exposing (Order, from)

-- Type enumerator
-- Modified from https://discourse.elm-lang.org/t/enumerate-function-for-non-infinite-custom-types-proposal/2636/7


type alias Order a =
    a -> Maybe a


from : a -> Order a -> List a
from current toNext =
    case toNext current of
        Just next ->
            current :: from next toNext

        Nothing ->
            [ current ]
