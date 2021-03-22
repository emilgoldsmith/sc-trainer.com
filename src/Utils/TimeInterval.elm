module Utils.TimeInterval exposing (Type, betweenTimestamps, displayOneDecimal, displayTwoDecimals, increment, zero)

import Time


type Type
    = TimeInterval Float


map : (Float -> Float) -> Type -> Type
map f (TimeInterval milliseconds) =
    TimeInterval (f milliseconds)


zero : Type
zero =
    TimeInterval 0


betweenTimestamps : { start : Time.Posix, end : Time.Posix } -> Type
betweenTimestamps { start, end } =
    TimeInterval <| toFloat <| Time.posixToMillis end - Time.posixToMillis start


increment : Float -> Type -> Type
increment msToIncrement =
    map ((+) msToIncrement)


type alias TimeUnits =
    { milliseconds : Int, seconds : Int, minutes : Int, hours : Int }


parseTimeUnits : Type -> TimeUnits
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


displayTwoDecimals : Type -> String
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


displayOneDecimal : Type -> String
displayOneDecimal interval =
    let
        milliseconds =
            (parseTimeUnits interval).milliseconds

        deciseconds =
            milliseconds // 100
    in
    displayWithoutDecimals interval ++ "." ++ String.fromInt deciseconds


displayWithoutDecimals : Type -> String
displayWithoutDecimals interval =
    let
        time =
            parseTimeUnits interval

        onlySeconds =
            String.fromInt time.seconds

        withMinutes =
            String.fromInt time.minutes ++ ":" ++ onlySeconds

        withHours =
            String.fromInt time.hours ++ ":" ++ withMinutes
    in
    if time.hours > 0 then
        withHours

    else if time.minutes > 0 then
        withMinutes

    else
        onlySeconds
