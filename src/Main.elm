module Main exposing (view)

import Browser
import Browser.Events as Events
import Html exposing (..)
import Json.Decode as Decode


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( BetweenTests, Cmd.none )


type Model
    = BetweenTests
    | TestRunning
    | EvaluateResult


type Msg
    = KeyUp Key
    | KeyDown Key


type Key
    = Space
    | SomeKey String
    | W


{-| Heavily inspired by <https://github.com/elm/browser/blob/1.0.2/notes/keyboard.md>
-}
decodeKey : Decode.Decoder Key
decodeKey =
    Decode.map toKey (Decode.field "key" Decode.string)


toKey : String -> Key
toKey keyString =
    case keyString of
        " " ->
            Space

        "w" ->
            W

        _ ->
            SomeKey keyString


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        BetweenTests ->
            Events.onKeyUp <| Decode.map KeyUp decodeKey

        TestRunning ->
            Sub.batch
                [ Events.onKeyDown <|
                    Decode.map KeyDown
                        decodeKey
                , Events.onMouseDown <|
                    Decode.succeed
                        (KeyDown <| SomeKey "mouseDown")
                ]

        _ ->
            Events.onKeyUp <| Decode.map KeyUp decodeKey


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        BetweenTests ->
            case msg of
                KeyUp Space ->
                    ( TestRunning, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        TestRunning ->
            case msg of
                KeyDown _ ->
                    ( EvaluateResult, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        EvaluateResult ->
            case msg of
                KeyUp Space ->
                    ( TestRunning, Cmd.none )

                KeyUp W ->
                    ( BetweenTests, Cmd.none )

                _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [] [ viewState model ]


viewState : Model -> Html Msg
viewState model =
    case model of
        BetweenTests ->
            text "Between Tests"

        TestRunning ->
            text "Test Running"

        EvaluateResult ->
            text "Evaluating Result"
