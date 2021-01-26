module Utils.Permutation exposing (Accessor, Permutation, apply, build, buildAccessor, reverse, toThePowerOf)

{-| This module implements cycle notation for permutations.
see [the Wikipedia entry](https://en.wikipedia.org/wiki/Permutation#Cycle_notation>)
for more information on this type of notation
-}

import Array exposing (Array)
import Set exposing (Set)


type Permutation location
    = Permutation (List (Cycle location))


type Cycle location
    = Cycle (Array location)


type Accessor location container value
    = Accessor (Getter location container value) (Setter location container value)


type alias Getter location container value =
    location -> container -> value


type alias Setter location container value =
    location -> value -> container -> container


build : List (List location) -> Permutation location
build =
    List.map Array.fromList >> List.map Cycle >> Permutation


buildAccessor : Getter location container value -> Setter location container value -> Accessor location container value
buildAccessor =
    Accessor


apply : Accessor location container value -> Permutation location -> container -> container
apply accessor (Permutation cycles) container =
    List.foldl (applyCycle accessor) container cycles


applyCycle : Accessor location container value -> Cycle location -> container -> container
applyCycle (Accessor getValue setValue) (Cycle cycleArray) originalContainer =
    let
        setThisLocation currentLocation ( previousLocation, currentContainer ) =
            let
                -- It's important we use originalContainer, since in currentContainer
                -- for all cases but the first time the previous value has already
                -- been set with its new value
                previousValue =
                    getValue previousLocation originalContainer

                nextContainer =
                    setValue currentLocation previousValue currentContainer
            in
            ( currentLocation, nextContainer )

        maybeLastLocation =
            Array.get (Array.length cycleArray - 1) cycleArray
    in
    maybeLastLocation
        |> Maybe.map
            (\lastLocation -> Array.foldl setThisLocation ( lastLocation, originalContainer ) cycleArray)
        |> Maybe.map Tuple.second
        -- If there was no last element of the array, it means the cycle was empty, which is equivalent
        -- to preserving the original container
        |> Maybe.withDefault originalContainer


reverse : Permutation a -> Permutation a
reverse (Permutation cycleList) =
    Permutation <| List.map reverseCycle cycleList


reverseCycle : Cycle a -> Cycle a
reverseCycle (Cycle cycleArray) =
    cycleArray
        |> (Array.toList
                >> List.reverse
                >> Array.fromList
           )
        |> Cycle


toThePowerOf : Int -> Permutation a -> Permutation a
toThePowerOf exponent (Permutation cycleList) =
    Permutation <| List.concatMap (cycleToThePowerOf exponent) cycleList


cycleToThePowerOf : Int -> Cycle a -> List (Cycle a)
cycleToThePowerOf exponent (Cycle cycleArray) =
    let
        cycleIndices =
            Array.initialize (Array.length cycleArray) identity

        addCycleStartingAt index ( cycleList, seen ) =
            let
                ( exponentCycle, newSeen ) =
                    getExponentCycleStartingAt index exponent seen cycleArray
            in
            ( exponentCycle :: cycleList, newSeen )
    in
    Array.foldl addCycleStartingAt ( [], Set.empty ) cycleIndices
        |> Tuple.first
        |> List.filter ((/=) Array.empty)
        |> List.map Cycle


getExponentCycleStartingAt : Int -> Int -> Set Int -> Array a -> ( Array a, Set Int )
getExponentCycleStartingAt index exponent seen cycle =
    traceExponentCycle exponent index cycle seen
        |> Tuple.mapFirst (Maybe.map Array.fromList)
        -- The Maybe is expected to be nothing if we pass it
        -- either an empty cycle or an out of range starting index.
        -- In both these cases it should make sense to return an empty cycle
        |> Tuple.mapFirst (Maybe.withDefault Array.empty)


traceExponentCycle : Int -> Int -> Array a -> Set Int -> ( Maybe (List a), Set Int )
traceExponentCycle exponent index cycle seen =
    let
        cycleLength =
            Array.length cycle

        arrayIndex =
            modBy cycleLength index
    in
    if Set.member arrayIndex seen then
        ( Just [], seen )

    else
        let
            currentValue =
                Array.get arrayIndex cycle

            ( restOfTrace, newSeen ) =
                traceExponentCycle exponent (index + exponent) cycle (Set.insert arrayIndex seen)
        in
        ( Maybe.map2 (::) currentValue restOfTrace, newSeen )
