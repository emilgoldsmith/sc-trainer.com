module UI.Text exposing (Conjunction(..), Separator(..), capitalizeFirst, grammaticalList)


type Conjunction
    = And
    | Or


type Separator
    = Comma
    | Semicolon


grammaticalList : { finalConjunction : Conjunction, separator : Separator } -> List String -> String
grammaticalList { finalConjunction, separator } strings =
    let
        separatorString =
            case separator of
                Comma ->
                    ","

                Semicolon ->
                    ";"

        conjunctionString =
            case finalConjunction of
                And ->
                    "and"

                Or ->
                    "or"
    in
    case strings of
        [] ->
            ""

        [ x ] ->
            x

        [ x, y ] ->
            x ++ separatorString ++ " " ++ conjunctionString ++ " " ++ y

        x :: xs ->
            x ++ separatorString ++ " " ++ grammaticalList { finalConjunction = finalConjunction, separator = separator } xs


capitalizeFirst : String -> String
capitalizeFirst s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s
