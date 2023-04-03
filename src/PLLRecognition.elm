module PLLRecognition exposing (specToPLLRecognitionString, specToPostAUFString)

import Cube.Advanced
import List.Nonempty
import PLL
import UI.Text


specToPLLRecognitionString : PLL.RecognitionSpecification -> String
specToPLLRecognitionString spec =
    let
        sortedSpec =
            sortForDisplay spec

        { patterns, absentPatterns, oppositelyColored, adjacentlyColored, identicallyColored, differentlyColored, noOtherStickersMatchThanThese, noOtherBlocksPresent } =
            sortedSpec.caseRecognition

        separator =
            UI.Text.Comma

        parts =
            [ patterns
                |> Maybe.map
                    (\patterns_ ->
                        "The easily identifiable pattern"
                            ++ (if List.Nonempty.length patterns_ > 1 then
                                    "s are"

                                else
                                    " is"
                               )
                            ++ " "
                            ++ nonemptyElementsToGrammaticalList
                                { article = Definite
                                , finalConjunction = UI.Text.And
                                , separator = separator
                                , forcePlural = False
                                }
                                (List.Nonempty.map PLL.Pattern patterns_)
                            ++ (if noOtherBlocksPresent then
                                    ". No other blocks appear"

                                else
                                    ""
                               )
                    )
                |> Maybe.map List.singleton
                |> Maybe.withDefault
                    (if noOtherBlocksPresent then
                        [ "No blocks appear at all" ]

                     else
                        []
                    )
            , absentPatterns
                |> Maybe.map
                    (\patterns_ ->
                        let
                            plural =
                                (List.Nonempty.length patterns_ > 1)
                                    || isPlural (PLL.Pattern <| List.Nonempty.head patterns_)
                        in
                        "There "
                            ++ (if plural then
                                    "are"

                                else
                                    "is"
                               )
                            ++ " no "
                            ++ nonemptyElementsToGrammaticalList
                                { article = NoArticle
                                , finalConjunction = UI.Text.Or
                                , separator = separator
                                , forcePlural = plural
                                }
                                (List.Nonempty.map PLL.Pattern patterns_)
                    )
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
            , oppositelyColored
                |> List.map
                    (\( first, second ) ->
                        nonemptyElementsToGrammaticalList
                            { article = Definite
                            , finalConjunction = UI.Text.And
                            , separator = separator
                            , forcePlural = False
                            }
                            first
                            ++ " "
                            ++ (if
                                    (List.Nonempty.length first > 1)
                                        || isPlural (List.Nonempty.head first)
                                then
                                    "are"

                                else
                                    "is"
                               )
                            ++ " the opposite color of "
                            ++ (if
                                    ((first == List.Nonempty.singleton (PLL.Pattern PLL.LeftHeadlights))
                                        && (second == List.Nonempty.singleton (PLL.Sticker PLL.SecondStickerFromLeft))
                                    )
                                        || ((first == List.Nonempty.singleton (PLL.Pattern PLL.RightHeadlights))
                                                && (second == List.Nonempty.singleton (PLL.Sticker PLL.SecondStickerFromRight))
                                           )
                                then
                                    "the enclosed sticker"

                                else
                                    nonemptyElementsToGrammaticalList
                                        { article = Definite
                                        , finalConjunction = UI.Text.And
                                        , separator = separator
                                        , forcePlural = False
                                        }
                                        second
                               )
                    )
            , adjacentlyColored
                |> List.map
                    (\( first, second ) ->
                        (if List.Nonempty.length first > 1 then
                            "the identically colored "
                                ++ nonemptyElementsToGrammaticalList
                                    { article = NoArticle
                                    , finalConjunction = UI.Text.And
                                    , separator = separator
                                    , forcePlural = False
                                    }
                                    first

                         else
                            nonemptyElementsToGrammaticalList
                                { article = Definite
                                , finalConjunction = UI.Text.And
                                , separator = separator
                                , forcePlural = False
                                }
                                first
                        )
                            ++ " "
                            ++ (if
                                    (List.Nonempty.length first > 1)
                                        || isPlural (List.Nonempty.head first)
                                then
                                    "are"

                                else
                                    "is"
                               )
                            ++ " the adjacent color of "
                            ++ (if
                                    ((first == List.Nonempty.singleton (PLL.Pattern PLL.LeftHeadlights))
                                        && (second == List.Nonempty.singleton (PLL.Sticker PLL.SecondStickerFromLeft))
                                    )
                                        || ((first == List.Nonempty.singleton (PLL.Pattern PLL.RightHeadlights))
                                                && (second == List.Nonempty.singleton (PLL.Sticker PLL.SecondStickerFromRight))
                                           )
                                then
                                    "the enclosed sticker"

                                else if List.Nonempty.length second > 1 then
                                    "the identically colored "
                                        ++ nonemptyElementsToGrammaticalList
                                            { article = NoArticle
                                            , finalConjunction = UI.Text.And
                                            , separator = separator
                                            , forcePlural = False
                                            }
                                            second

                                else
                                    nonemptyElementsToGrammaticalList
                                        { article = Definite
                                        , finalConjunction = UI.Text.And
                                        , separator = separator
                                        , forcePlural = False
                                        }
                                        second
                               )
                    )
            , identicallyColored
                |> List.map
                    (\elements ->
                        minLength2ElementsToGrammaticalList
                            { article = Definite
                            , finalConjunction = UI.Text.And
                            , separator = separator
                            , forcePlural = False
                            }
                            elements
                            ++ " are "
                            ++ (if lengthOfMinLength2List elements > 2 then
                                    "all "

                                else
                                    ""
                               )
                            ++ "the same color"
                    )
            , differentlyColored
                |> List.map
                    (\elements ->
                        minLength2ElementsToGrammaticalList
                            { article = Definite
                            , finalConjunction = UI.Text.And
                            , separator = separator
                            , forcePlural = False
                            }
                            elements
                            ++ " are "
                            ++ (if lengthOfMinLength2List elements > 2 then
                                    "all "

                                else
                                    ""
                               )
                            ++ "different colors from each other"
                    )
            , noOtherStickersMatchThanThese
                |> Maybe.map
                    (\elements ->
                        "There are no other stickers that match the color of any other sticker except for "
                            ++ nonemptyElementsToGrammaticalList
                                { article = Definite
                                , finalConjunction = UI.Text.And
                                , separator = separator
                                , forcePlural = False
                                }
                                elements
                    )
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
            ]
    in
    String.append
        (parts
            |> List.concat
            |> List.map UI.Text.capitalizeFirst
            |> String.join ". "
            |> String.trim
        )
        "."


specToPostAUFString : PLL.RecognitionSpecification -> String
specToPostAUFString spec =
    let
        separator =
            UI.Text.Comma

        sortedSpec =
            sortForDisplay spec

        { postAUFRecognition } =
            sortedSpec

        listOfPostAUFPatternsToLookAt =
            postAUFRecognition
                |> List.Nonempty.toList
                |> List.map
                    (\({ elementsWithOriginalFace, finalFace } as arg) ->
                        nonemptyElementsToGrammaticalList
                            { article = Definite
                            , finalConjunction = UI.Text.And
                            , separator = separator
                            , forcePlural = False
                            }
                            (List.Nonempty.map Tuple.first elementsWithOriginalFace)
                            ++ (if staysInSamePlace arg then
                                    " which will stay in place"

                                else
                                    " which will end up on the "
                                        ++ (case finalFace of
                                                Cube.Advanced.UpOrDown Cube.Advanced.U ->
                                                    "top"

                                                Cube.Advanced.UpOrDown Cube.Advanced.D ->
                                                    "bottom"

                                                Cube.Advanced.LeftOrRight Cube.Advanced.L ->
                                                    "left"

                                                Cube.Advanced.LeftOrRight Cube.Advanced.R ->
                                                    "right"

                                                Cube.Advanced.FrontOrBack Cube.Advanced.F ->
                                                    "front"

                                                Cube.Advanced.FrontOrBack Cube.Advanced.B ->
                                                    "back"
                                           )
                                        ++ " side of the cube"
                               )
                    )
    in
    String.append
        (UI.Text.grammaticalList
            { finalConjunction = UI.Text.Or, separator = UI.Text.Semicolon }
            listOfPostAUFPatternsToLookAt
            |> UI.Text.capitalizeFirst
        )
        "."


type Article
    = NoArticle
    | Definite


elementToString : { article : Article, forcePlural : Bool } -> PLL.RecognitionElement -> String
elementToString { article, forcePlural } element =
    let
        { object, pluralized } =
            case element of
                PLL.Pattern pattern ->
                    case pattern of
                        PLL.Bookends ->
                            { indefiniteArticle = Nothing, object = "bookends", pluralized = "bookends" }

                        PLL.LeftHeadlights ->
                            { indefiniteArticle = Nothing, object = "headlights on the left", pluralized = "headlights on the left" }

                        PLL.RightHeadlights ->
                            { indefiniteArticle = Nothing, object = "headlights on the right", pluralized = "headlights on the right" }

                        PLL.RightOutsideTwoBar ->
                            { indefiniteArticle = Just "an", object = "outside two-bar on the right", pluralized = "outside two-bars on the right" }

                        PLL.LeftOutsideTwoBar ->
                            { indefiniteArticle = Just "an", object = "outside two-bar on the left", pluralized = "outside two-bars on the left" }

                        PLL.RightInsideTwoBar ->
                            { indefiniteArticle = Just "an", object = "inside two-bar on the right", pluralized = "inside two-bars on the right" }

                        PLL.LeftInsideTwoBar ->
                            { indefiniteArticle = Just "an", object = "inside two-bar on the left", pluralized = "inside two-bars on the left" }

                        PLL.LeftThreeBar ->
                            { indefiniteArticle = Just "a", object = "three-bar on the left", pluralized = "three-bars on the left" }

                        PLL.RightThreeBar ->
                            { indefiniteArticle = Just "a", object = "three-bar on the right", pluralized = "three-bars on the right" }

                        PLL.LeftFourChecker ->
                            { indefiniteArticle = Just "a", object = "four checker pattern on the left", pluralized = "four checker patterns on the left" }

                        PLL.RightFourChecker ->
                            { indefiniteArticle = Just "a", object = "four checker pattern on the right", pluralized = "four checker patterns on the right" }

                        PLL.InnerFourChecker ->
                            { indefiniteArticle = Just "an", object = "inside four checker pattern", pluralized = "inside four checker patterns" }

                        PLL.LeftFiveChecker ->
                            { indefiniteArticle = Just "a", object = "five checker pattern on the left", pluralized = "five checker patterns on the left" }

                        PLL.RightFiveChecker ->
                            { indefiniteArticle = Just "a", object = "five checker pattern on the right", pluralized = "five checker patterns on the right" }

                        PLL.SixChecker ->
                            { indefiniteArticle = Just "a", object = "six checker pattern", pluralized = "six checker patterns" }

                PLL.Sticker sticker ->
                    case sticker of
                        PLL.FirstStickerFromLeft ->
                            { indefiniteArticle = Nothing, object = "first sticker from the left", pluralized = "first stickers from the left" }

                        PLL.FirstStickerFromRight ->
                            { indefiniteArticle = Nothing, object = "first sticker from the right", pluralized = "first stickers from the right" }

                        PLL.SecondStickerFromLeft ->
                            { indefiniteArticle = Nothing, object = "second sticker from the left", pluralized = "second stickers from the left" }

                        PLL.SecondStickerFromRight ->
                            { indefiniteArticle = Nothing, object = "second sticker from the right", pluralized = "second stickers from the right" }

                        PLL.ThirdStickerFromLeft ->
                            { indefiniteArticle = Nothing, object = "third sticker from the left", pluralized = "third stickers from the left" }

                        PLL.ThirdStickerFromRight ->
                            { indefiniteArticle = Nothing, object = "third sticker from the right", pluralized = "third stickers from the right" }

        pluralHandledObject =
            if forcePlural then
                pluralized

            else
                object
    in
    case article of
        NoArticle ->
            pluralHandledObject

        -- Indefinite ->
        --     (indefiniteArticle
        --         |> Maybe.map (\x -> x ++ " ")
        --         |> Maybe.withDefault ""
        --     )
        --         ++ pluralHandledObject
        Definite ->
            "the " ++ pluralHandledObject


staysInSamePlace :
    { elementsWithOriginalFace : List.Nonempty.Nonempty ( PLL.RecognitionElement, Cube.Advanced.Face )
    , finalFace : Cube.Advanced.Face
    }
    -> Bool
staysInSamePlace { elementsWithOriginalFace, finalFace } =
    elementsWithOriginalFace
        |> List.Nonempty.all
            (Tuple.second >> (==) finalFace)


sortForDisplay : PLL.RecognitionSpecification -> PLL.RecognitionSpecification
sortForDisplay { caseRecognition, postAUFRecognition } =
    { caseRecognition =
        { patterns =
            Maybe.map
                (List.Nonempty.sortWith sortPatternsByFurthestLeftComparison)
                caseRecognition.patterns
        , absentPatterns =
            Maybe.map
                (List.Nonempty.sortWith sortPatternsByFurthestLeftComparison)
                caseRecognition.absentPatterns
        , oppositelyColored =
            caseRecognition.oppositelyColored
                |> List.map ensurePatternsAreInFirstSpot
                |> List.map
                    (Tuple.mapBoth
                        (List.Nonempty.sortWith sortByFurthestLeftComparison)
                        (List.Nonempty.sortWith sortByFurthestLeftComparison)
                    )
        , adjacentlyColored =
            caseRecognition.adjacentlyColored
                |> List.map ensurePatternsAreInFirstSpot
                |> List.map
                    (Tuple.mapBoth
                        (List.Nonempty.sortWith sortByFurthestLeftComparison)
                        (List.Nonempty.sortWith sortByFurthestLeftComparison)
                    )
        , identicallyColored =
            List.map
                (sortMinLength2ListWith sortByFurthestLeftComparison)
                caseRecognition.identicallyColored
        , differentlyColored =
            List.map
                (sortMinLength2ListWith sortByFurthestLeftComparison)
                caseRecognition.differentlyColored
        , noOtherStickersMatchThanThese =
            Maybe.map
                (List.Nonempty.sortWith sortByFurthestLeftComparison)
                caseRecognition.noOtherStickersMatchThanThese
        , noOtherBlocksPresent = caseRecognition.noOtherBlocksPresent
        }
    , postAUFRecognition =
        List.Nonempty.map
            (\arg ->
                { arg
                    | elementsWithOriginalFace =
                        List.Nonempty.sortWith
                            sortTupleByFurthestLeftComparison
                            arg.elementsWithOriginalFace
                }
            )
            postAUFRecognition
    }


sortTupleByFurthestLeftComparison : ( PLL.RecognitionElement, a ) -> ( PLL.RecognitionElement, a ) -> Order
sortTupleByFurthestLeftComparison ( a, _ ) ( b, _ ) =
    sortByFurthestLeftComparison a b


sortByFurthestLeftComparison : PLL.RecognitionElement -> PLL.RecognitionElement -> Order
sortByFurthestLeftComparison a b =
    let
        toFloat element =
            case element of
                PLL.Sticker sticker ->
                    case sticker of
                        PLL.FirstStickerFromLeft ->
                            1

                        PLL.SecondStickerFromLeft ->
                            2

                        PLL.ThirdStickerFromLeft ->
                            3

                        PLL.ThirdStickerFromRight ->
                            4

                        PLL.SecondStickerFromRight ->
                            5

                        PLL.FirstStickerFromRight ->
                            6

                PLL.Pattern pattern ->
                    case pattern of
                        PLL.Bookends ->
                            1.5

                        PLL.LeftHeadlights ->
                            1

                        PLL.RightHeadlights ->
                            4

                        PLL.RightOutsideTwoBar ->
                            5

                        PLL.LeftOutsideTwoBar ->
                            1

                        PLL.RightInsideTwoBar ->
                            4

                        PLL.LeftInsideTwoBar ->
                            2

                        PLL.LeftThreeBar ->
                            1

                        PLL.RightThreeBar ->
                            4

                        PLL.LeftFourChecker ->
                            1

                        PLL.RightFourChecker ->
                            3

                        PLL.InnerFourChecker ->
                            2

                        PLL.LeftFiveChecker ->
                            1

                        PLL.RightFiveChecker ->
                            2

                        PLL.SixChecker ->
                            1
    in
    compare (toFloat a) (toFloat b)


sortPatternsByFurthestLeftComparison : PLL.RecognitionPattern -> PLL.RecognitionPattern -> Order
sortPatternsByFurthestLeftComparison a b =
    sortByFurthestLeftComparison (PLL.Pattern a) (PLL.Pattern b)


ensurePatternsAreInFirstSpot :
    ( List.Nonempty.Nonempty PLL.RecognitionElement, List.Nonempty.Nonempty PLL.RecognitionElement )
    -> ( List.Nonempty.Nonempty PLL.RecognitionElement, List.Nonempty.Nonempty PLL.RecognitionElement )
ensurePatternsAreInFirstSpot ( a, b ) =
    if
        b
            |> List.Nonempty.toList
            |> List.filter
                (\element ->
                    case element of
                        PLL.Pattern _ ->
                            True

                        PLL.Sticker _ ->
                            False
                )
            |> List.isEmpty
    then
        ( a, b )

    else
        ( b, a )


elementToGrammaticalList : { article : Article, finalConjunction : UI.Text.Conjunction, separator : UI.Text.Separator, forcePlural : Bool } -> List PLL.RecognitionElement -> String
elementToGrammaticalList { article, finalConjunction, separator, forcePlural } list =
    list
        |> List.map (elementToString { article = article, forcePlural = forcePlural })
        |> UI.Text.grammaticalList { finalConjunction = finalConjunction, separator = separator }


nonemptyElementsToGrammaticalList : { article : Article, finalConjunction : UI.Text.Conjunction, separator : UI.Text.Separator, forcePlural : Bool } -> List.Nonempty.Nonempty PLL.RecognitionElement -> String
nonemptyElementsToGrammaticalList args =
    List.Nonempty.toList >> elementToGrammaticalList args


minLength2ElementsToGrammaticalList : { article : Article, finalConjunction : UI.Text.Conjunction, separator : UI.Text.Separator, forcePlural : Bool } -> ( PLL.RecognitionElement, PLL.RecognitionElement, List PLL.RecognitionElement ) -> String
minLength2ElementsToGrammaticalList args ( first, second, rest ) =
    elementToGrammaticalList args (first :: second :: rest)


lengthOfMinLength2List : ( a, a, List a ) -> Int
lengthOfMinLength2List ( _, _, list ) =
    2 + List.length list


sortMinLength2ListWith : (a -> a -> Order) -> ( a, a, List a ) -> ( a, a, List a )
sortMinLength2ListWith comp ( first, second, tail ) =
    let
        allSorted =
            List.sortWith comp (first :: second :: tail)
    in
    case allSorted of
        x1 :: x2 :: xs ->
            ( x1, x2, xs )

        -- This will obviously never happen as we just created the list above with 2
        -- elements in it at the least. Just for the types and simpler code than
        -- trying to sort more manually and moving things between the first
        -- spots and the tail etc.
        _ ->
            ( first, second, tail )


isPlural : PLL.RecognitionElement -> Bool
isPlural element =
    case element of
        PLL.Sticker _ ->
            False

        PLL.Pattern pattern ->
            case pattern of
                PLL.Bookends ->
                    True

                PLL.LeftHeadlights ->
                    True

                PLL.RightHeadlights ->
                    True

                PLL.RightOutsideTwoBar ->
                    False

                PLL.LeftOutsideTwoBar ->
                    False

                PLL.RightInsideTwoBar ->
                    False

                PLL.LeftInsideTwoBar ->
                    False

                _ ->
                    False
