module Models.Algorithm exposing (Algorithm, Turn(..), TurnDirection(..), TurnLength(..), Turnable(..), allTurnDirections, allTurnLengths, allTurnables, allTurns, appendTo, build, extractInternals, fromString, inverse)

import Monads.ListM as ListM
import Parser.Advanced as Parser exposing ((|.), (|=), Parser)
import Utils.Enumerator



-- ALGORITHM MODEL


type Algorithm
    = Algorithm (List Turn)


type Turn
    = Turn Turnable TurnLength TurnDirection


type Turnable
    = -- Single face turns
      U
    | D
    | L
    | R
    | F
    | B
      -- Slice turns
    | M
    | S
    | E


type TurnLength
    = OneQuarter
    | Halfway
    | ThreeQuarters


type TurnDirection
    = Clockwise
    | CounterClockwise



-- HELPERS


extractInternals : Algorithm -> List Turn
extractInternals alg =
    case alg of
        Algorithm turnList ->
            turnList


build : List Turn -> Algorithm
build =
    Algorithm


appendTo : Algorithm -> Algorithm -> Algorithm
appendTo (Algorithm a) (Algorithm b) =
    Algorithm (a ++ b)


inverse : Algorithm -> Algorithm
inverse =
    let
        map f (Algorithm turnList) =
            Algorithm (f turnList)

        flipDirection direction =
            case direction of
                Clockwise ->
                    CounterClockwise

                CounterClockwise ->
                    Clockwise

        flipTurn (Turn a b direction) =
            Turn a b (flipDirection direction)
    in
    map <| List.reverse >> List.map flipTurn


fromString : String -> Result String Algorithm
fromString string =
    Parser.run algParser string
        |> Result.mapError (renderError string)



-- PARSER


type Problem
    = ExpectingFaceOrSlice
    | ExpectingNumQuarterTurns
    | ExpectingTurnDirection
    | UnexpectedCharacter
    | EmptyAlgorithm


algParser : Parser Never Problem Algorithm
algParser =
    let
        looper currentAlgorithm =
            Parser.oneOf
                [ Parser.succeed (\turn -> Parser.Loop (turn :: currentAlgorithm))
                    |= turnParser
                    |. Parser.chompWhile (\c -> c == ' ' || c == '\t')
                , Parser.succeed ()
                    |. Parser.end UnexpectedCharacter
                    |> Parser.map
                        (\_ -> Parser.Done (List.reverse currentAlgorithm))
                ]

        turnParser =
            Parser.succeed Turn
                |= turnableParser
                |= turnLengthParser
                |= directionParser

        turnableParser =
            let
                turnableToTokenParser turnable =
                    let
                        turnableToString : Turnable -> String
                        turnableToString layer =
                            case layer of
                                U ->
                                    "U"

                                D ->
                                    "D"

                                L ->
                                    "L"

                                R ->
                                    "R"

                                F ->
                                    "F"

                                B ->
                                    "B"

                                M ->
                                    "M"

                                S ->
                                    "S"

                                E ->
                                    "E"

                        token =
                            Parser.token (Parser.Token (turnableToString turnable) ExpectingFaceOrSlice)
                    in
                    Parser.map (\_ -> turnable) token
            in
            Parser.oneOf (List.map turnableToTokenParser allTurnables)

        turnLengthParser =
            Parser.oneOf
                [ Parser.map (\_ -> Halfway) <| Parser.token (Parser.Token "2" ExpectingNumQuarterTurns)
                , Parser.map (\_ -> ThreeQuarters) <| Parser.token (Parser.Token "3" ExpectingNumQuarterTurns)
                , Parser.map (\_ -> OneQuarter) <| Parser.token (Parser.Token "" ExpectingNumQuarterTurns)
                ]

        directionParser =
            Parser.oneOf
                [ Parser.map (\_ -> CounterClockwise) <| Parser.token (Parser.Token "'" ExpectingTurnDirection)
                , Parser.map (\_ -> Clockwise) <| Parser.token (Parser.Token "" ExpectingTurnDirection)
                ]

        verifyNotEmpty (Algorithm turnList) =
            case List.length turnList of
                0 ->
                    Parser.problem EmptyAlgorithm

                _ ->
                    Parser.succeed (Algorithm turnList)
    in
    Parser.succeed Algorithm |= Parser.loop [] looper |> Parser.andThen verifyNotEmpty


renderError : String -> List (Parser.DeadEnd Never Problem) -> String
renderError string deadEnds =
    let
        renderDeadEnd d =
            String.fromInt d.row ++ ":" ++ String.fromInt d.col ++ " : " ++ renderProblem d.problem
    in
    string ++ "    " ++ (String.join ". " <| List.map renderDeadEnd deadEnds)


renderProblem : Problem -> String
renderProblem problem =
    case problem of
        ExpectingFaceOrSlice ->
            "Expecting face or slice"

        ExpectingNumQuarterTurns ->
            "Expecting num quarter turns"

        ExpectingTurnDirection ->
            "Expecting turn direction"

        UnexpectedCharacter ->
            "Unexpected character"

        EmptyAlgorithm ->
            "An empty algorithm makes no sense as user input"



-- TYPE ENUMERATORS (as lists)


{-| All possible combinations of turnables, lengths and directions

    List.length allTurns
    --> List.length allTurnables * List.length allTurnLengths * List.length allTurnDirections

-}
allTurns : List Turn
allTurns =
    ListM.return Turn
        |> ListM.applicative (ListM.fromList allTurnables)
        |> ListM.applicative (ListM.fromList allTurnLengths)
        |> ListM.applicative (ListM.fromList allTurnDirections)
        |> ListM.toList


{-| All possible turnables

    List.length allTurnables --> 9

-}
allTurnables : List Turnable
allTurnables =
    let
        fromU layer =
            case layer of
                U ->
                    Just D

                D ->
                    Just L

                L ->
                    Just R

                R ->
                    Just F

                F ->
                    Just B

                B ->
                    Just M

                M ->
                    Just S

                S ->
                    Just E

                E ->
                    Nothing
    in
    Utils.Enumerator.from U fromU


{-| All possible turn lengths

    List.length allTurnLengths --> 3

-}
allTurnLengths : List TurnLength
allTurnLengths =
    let
        fromOneQuarter length =
            case length of
                OneQuarter ->
                    Just Halfway

                Halfway ->
                    Just ThreeQuarters

                ThreeQuarters ->
                    Nothing
    in
    Utils.Enumerator.from OneQuarter fromOneQuarter


{-| All possible turn directions

    List.length allTurnDirections --> 2

-}
allTurnDirections : List TurnDirection
allTurnDirections =
    let
        fromClockwise direction =
            case direction of
                Clockwise ->
                    Just CounterClockwise

                CounterClockwise ->
                    Nothing
    in
    Utils.Enumerator.from Clockwise fromClockwise
