module Utils.MappedPermutation exposing (MappedPermutation, apply, build, buildAccessor, compose, identity, reversePermutationButKeepMaps, toThePowerOf)

{-| Not exposing a reverse as it doesn't seem to have a clear definition.

For one, it's hard if not impossible to programatically inverse any given function,
but one must also answer if the reverse of a mapped permutation is actually meant
to apply the inverse map?

One could also try doing the cycle to the power of (length - 1), but that makes a
not necessarily correct assumption about applying map over (length - 1) is the same
as applying it once "in reverse". So for now we just don't expose a reverse method

-}

import Array exposing (Array)
import Set exposing (Set)
import Utils.Permutation as Permutation exposing (Permutation)


type MappedPermutation location value
    = MappedPermutation (List (MappedCycle location value))


type MappedCycle location value
    = MappedCycle (Array ( location, value -> value ))


type Accessor location container value
    = Accessor (Getter location container value) (Setter location container value)


type alias Getter location container value =
    location -> container -> value


type alias Setter location container value =
    location -> value -> container -> container


build : List (List ( location, value -> value )) -> MappedPermutation location value
build mappedCycles =
    MappedPermutation <| List.map (Array.fromList >> MappedCycle) mappedCycles


buildAccessor : Getter location container value -> Setter location container value -> Accessor location container value
buildAccessor =
    Accessor


identity : MappedPermutation location value
identity =
    MappedPermutation []


compose : MappedPermutation location value -> MappedPermutation location value -> MappedPermutation location value
compose (MappedPermutation cyclesA) (MappedPermutation cyclesB) =
    MappedPermutation (cyclesA ++ cyclesB)


apply : Accessor location container value -> MappedPermutation location value -> container -> container
apply accessor mappedPermutation container =
    let
        withMapsApplied =
            applyMaps accessor mappedPermutation container
    in
    Permutation.apply (toPermutationAccessor accessor) (toPermutation mappedPermutation) <|
        withMapsApplied


applyMaps : Accessor location container value -> MappedPermutation location value -> container -> container
applyMaps accessor (MappedPermutation cycles) container =
    List.foldl (applyMapsForCycle accessor) container cycles


applyMapsForCycle : Accessor location container value -> MappedCycle location value -> container -> container
applyMapsForCycle accessor (MappedCycle cycleArray) container =
    Array.foldl (applySingleMap accessor) container cycleArray


applySingleMap : Accessor location container value -> ( location, value -> value ) -> container -> container
applySingleMap (Accessor getValue setValue) ( location, f ) container =
    getValue location container
        |> f
        |> (\value -> setValue location value container)


toPermutation : MappedPermutation location value -> Permutation location
toPermutation (MappedPermutation mappedCycles) =
    Permutation.build <| List.map toCycle mappedCycles


toCycle : MappedCycle location value -> List location
toCycle (MappedCycle array) =
    Array.map Tuple.first array |> Array.toList


toPermutationAccessor : Accessor location container value -> Permutation.Accessor location container value
toPermutationAccessor (Accessor getValue setValue) =
    Permutation.buildAccessor getValue setValue


reversePermutationButKeepMaps : MappedPermutation a b -> MappedPermutation a b
reversePermutationButKeepMaps (MappedPermutation mappedCycles) =
    List.map (\(MappedCycle array) -> Array.toList array) mappedCycles
        |> List.map List.reverse
        |> build


toThePowerOf : Int -> MappedPermutation location value -> MappedPermutation location value
toThePowerOf exponent (MappedPermutation cycleList) =
    MappedPermutation <| List.concatMap (cycleToThePowerOf exponent) cycleList


cycleToThePowerOf : Int -> MappedCycle location value -> List (MappedCycle location value)
cycleToThePowerOf exponent (MappedCycle cycleArray) =
    let
        cycleIndices =
            Array.initialize (Array.length cycleArray) Basics.identity

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
        |> List.map MappedCycle


getExponentCycleStartingAt : Int -> Int -> Set Int -> Array ( location, value -> value ) -> ( Array ( location, value -> value ), Set Int )
getExponentCycleStartingAt index exponent seen cycle =
    traceExponentCycle exponent index cycle seen
        |> Tuple.mapFirst (Maybe.map Array.fromList)
        -- The Maybe is expected to be nothing if we pass it
        -- either an empty cycle or an out of range starting index.
        -- In both these cases it should make sense to return an empty cycle
        |> Tuple.mapFirst (Maybe.withDefault Array.empty)


traceExponentCycle : Int -> Int -> Array ( location, value -> value ) -> Set Int -> ( Maybe (List ( location, value -> value )), Set Int )
traceExponentCycle exponent index cycle seen =
    if Set.member index seen then
        ( Just [], seen )

    else
        let
            location =
                Array.get index cycle |> Maybe.map Tuple.first

            newMapper =
                composeAllMapsEncountered index exponent cycle

            valueWithUpdatedMap =
                Maybe.map2 Tuple.pair location newMapper

            nextIndex =
                modBy (Array.length cycle) (index + exponent)

            ( restOfTrace, newSeen ) =
                traceExponentCycle exponent nextIndex cycle (Set.insert index seen)
        in
        ( Maybe.map2 (::) valueWithUpdatedMap restOfTrace, newSeen )


composeAllMapsEncountered : Int -> Int -> Array ( location, value -> value ) -> Maybe (value -> value)
composeAllMapsEncountered index exponent array =
    if exponent <= 0 then
        Just Basics.identity

    else
        let
            currentMap =
                Array.get index array |> Maybe.map Tuple.second

            nextIndex =
                modBy (Array.length array) (index + 1)

            restOfFunctionsComposed =
                composeAllMapsEncountered nextIndex (exponent - 1) array
        in
        Maybe.map2 (>>) currentMap restOfFunctionsComposed
