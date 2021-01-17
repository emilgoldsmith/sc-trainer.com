module Models.Algorithm exposing (Algorithm, Turn(..), TurnDirection(..), TurnLength(..), Turnable(..), allTurnDirections, allTurnLengths, allTurnables, allTurns, build, extractInternals, fromString, inverse)

import Monads.List as ListM
import Parser.Advanced as Parser exposing ((|.), (|=), Parser)
import Utils.Enumerator



-- ALGORITHM MODEL


type Algorithm
    = Algorithm (List Turn)


type Turn
    = Turn Turnable TurnLength TurnDirection


type Turnable
    = U


type TurnLength
    = OneQuarter
    | DoubleTurn
    | ThreeQuarters


type TurnDirection
    = Clockwise
    | CounterClockwise


extractInternals : Algorithm -> List Turn
extractInternals alg =
    case alg of
        Algorithm turnList ->
            turnList


build : List Turn -> Algorithm
build =
    Algorithm


flipDirection : TurnDirection -> TurnDirection
flipDirection direction =
    case direction of
        Clockwise ->
            CounterClockwise

        CounterClockwise ->
            Clockwise


fromString : String -> Result String Algorithm
fromString string =
    Parser.run algParser string
        |> Result.mapError (renderError string)


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


type Problem
    = ExpectingFaceOrSlice
    | ExpectingNumQuarterTurns
    | ExpectingTurnDirection
    | UnexpectedCharacter


algParser : Parser Never Problem Algorithm
algParser =
    let
        turnableToString : Turnable -> String
        turnableToString layer =
            case layer of
                U ->
                    "U"

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
                |= sliceParser
                |= numQuarterTurnsParser
                |= directionParser

        sliceParser =
            Parser.oneOf (List.map (\layer -> Parser.map (\_ -> layer) (Parser.Token (turnableToString layer) ExpectingFaceOrSlice |> Parser.token)) allTurnables)

        numQuarterTurnsParser =
            Parser.oneOf
                [ Parser.map (\_ -> DoubleTurn) <| Parser.token (Parser.Token "2" ExpectingNumQuarterTurns)
                , Parser.map (\_ -> ThreeQuarters) <| Parser.token (Parser.Token "3" ExpectingNumQuarterTurns)
                , Parser.map (\_ -> OneQuarter) <| Parser.token (Parser.Token "" ExpectingNumQuarterTurns)
                ]

        directionParser =
            Parser.oneOf
                [ Parser.map (\_ -> CounterClockwise) <| Parser.token (Parser.Token "'" ExpectingTurnDirection)
                , Parser.map (\_ -> Clockwise) <| Parser.token (Parser.Token "" ExpectingTurnDirection)
                ]
    in
    Parser.succeed (::) |= turnParser |= Parser.loop [] looper |> Parser.map Algorithm


inverse : Algorithm -> Algorithm
inverse =
    let
        flipTurn (Turn a b direction) =
            Turn a b (flipDirection direction)
    in
    map <| List.reverse >> List.map flipTurn


map : (List Turn -> List Turn) -> Algorithm -> Algorithm
map f (Algorithm turnList) =
    Algorithm (f turnList)



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

    List.length allTurnables --> 1

-}
allTurnables : List Turnable
allTurnables =
    let
        fromU : Utils.Enumerator.Order Turnable
        fromU layer =
            case layer of
                U ->
                    Nothing
    in
    Utils.Enumerator.from U fromU


{-| All possible turn lengths

    List.length allTurnLengths -> 3

-}
allTurnLengths : List TurnLength
allTurnLengths =
    let
        fromOneQuarter : Utils.Enumerator.Order TurnLength
        fromOneQuarter length =
            case length of
                OneQuarter ->
                    Just DoubleTurn

                DoubleTurn ->
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
        fromClockwise : Utils.Enumerator.Order TurnDirection
        fromClockwise direction =
            case direction of
                Clockwise ->
                    Just CounterClockwise

                CounterClockwise ->
                    Nothing
    in
    Utils.Enumerator.from Clockwise fromClockwise
