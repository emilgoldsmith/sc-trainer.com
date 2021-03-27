module Utils.TimeInterval exposing (TimeInterval, betweenTimestamps, displayOneDecimal, displayTwoDecimals, increment, zero)

import Time


type TimeInterval
    = TimeInterval Float


map : (Float -> Float) -> TimeInterval -> TimeInterval
map f (TimeInterval milliseconds) =
    TimeInterval (f milliseconds)


zero : TimeInterval
zero =
    TimeInterval 0


betweenTimestamps : { start : Time.Posix, end : Time.Posix } -> TimeInterval
betweenTimestamps { start, end } =
    TimeInterval <| toFloat <| Time.posixToMillis end - Time.posixToMillis start


increment : Float -> TimeInterval -> TimeInterval
increment msToIncrement =
    map ((+) msToIncrement)


type alias TimeUnits =
    { milliseconds : Int, seconds : Int, minutes : Int, hours : Int }


parseTimeUnits : TimeInterval -> TimeUnits
parseTimeUnits (TimeInterval floatMilliseconds) =
    let
        millisecondsElapsed =
            round floatMilliseconds
    in
    { milliseconds = remainderBy 1000 millisecondsElapsed
    , seconds = remainderBy 60 (millisecondsElapsed // 1000)
    , minutes = remainderBy 60 (millisecondsElapsed // (60 * 1000))
    , hours = millisecondsElapsed // (60 * 60 * 1000)
    }


displayTwoDecimals : TimeInterval -> String
displayTwoDecimals interval =
    let
        milliseconds =
            (parseTimeUnits interval).milliseconds

        centiseconds =
            milliseconds // 10

        precedingZeroes =
            if centiseconds < 10 then
                "0"

            else
                ""
    in
    displayWithoutDecimals interval ++ "." ++ precedingZeroes ++ String.fromInt centiseconds


displayOneDecimal : TimeInterval -> String
displayOneDecimal interval =
    let
        milliseconds =
            (parseTimeUnits interval).milliseconds

        deciseconds =
            milliseconds // 100
    in
    displayWithoutDecimals interval ++ "." ++ String.fromInt deciseconds


displayWithoutDecimals : TimeInterval -> String
displayWithoutDecimals interval =
    let
        time =
            parseTimeUnits interval
    in
    if time.hours > 0 then
        String.fromInt time.hours ++ ":" ++ withTwoDigitsEnsured time.minutes ++ ":" ++ withTwoDigitsEnsured time.seconds

    else if time.minutes > 0 then
        String.fromInt time.minutes ++ ":" ++ withTwoDigitsEnsured time.seconds

    else
        String.fromInt time.seconds


withTwoDigitsEnsured : Int -> String
withTwoDigitsEnsured number =
    if number < 0 then
        -- Should never happen
        "00"

    else if number < 10 then
        "0" ++ String.fromInt number

    else
        String.fromInt number
