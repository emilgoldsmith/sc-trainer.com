module Utils.TimeInterval exposing (TimeInterval, displayOneDecimal, displayTwoDecimals, increment, zero)


type TimeInterval
    = TimeInterval Float


map : (Float -> Float) -> TimeInterval -> TimeInterval
map f (TimeInterval milliseconds) =
    TimeInterval (f milliseconds)


zero : TimeInterval
zero =
    TimeInterval 0


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
