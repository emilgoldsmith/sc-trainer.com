module Context exposing (BuildInput, Context, Msg, build, subscriptions)

import Browser.Events as Events
import Browser.Navigation
import Element
import Json.Decode as Decode
import UI
import ViewportSize


type alias Context =
    { viewportSize : ViewportSize.ViewportSize
    , userHasKeyboard : Bool
    , userHasTouchScreen : Bool
    , navigationKey : Browser.Navigation.Key
    , palette : UI.Palette
    }


type alias BuildInput =
    { viewportSize : { width : Int, height : Int }
    , userHasKeyboard : Bool
    , userHasTouchScreen : Bool
    , navigationKey : Browser.Navigation.Key
    , palette : UI.Palette
    }


build : BuildInput -> Context
build input =
    { viewportSize = ViewportSize.build input.viewportSize
    , userHasKeyboard = input.userHasKeyboard
    , userHasTouchScreen = input.userHasTouchScreen
    , navigationKey = input.navigationKey
    , palette = input.palette
    }


type Msg
    = WindowResized Int Int
    | KeyboardWasUsed
    | DoNothing


guessIfUserHasKeyboard : { a | userHasTouchScreen : Bool, viewportSize : { width : Int, height : Int } } -> Bool
guessIfUserHasKeyboard { userHasTouchScreen, viewportSize } =
    let
        isLargeScreen =
            case Element.classifyDevice viewportSize |> .class of
                Element.Phone ->
                    False

                Element.Tablet ->
                    False

                Element.Desktop ->
                    True

                Element.BigDesktop ->
                    True
    in
    -- Basically if there's no touch screen we assume they must have a keyboard.
    -- If they do have a touch screen the best we can do is guess based on screen size
    not userHasTouchScreen || isLargeScreen


subscriptions : Context -> Sub Msg
subscriptions context =
    Sub.batch
        [ Events.onResize WindowResized
        , if context.userHasKeyboard then
            Sub.none

          else
            Sub.batch
                [ Events.onKeyDown (Decode.succeed KeyboardWasUsed)
                , Events.onKeyPress (Decode.succeed KeyboardWasUsed)
                , Events.onKeyUp (Decode.succeed KeyboardWasUsed)
                ]
        ]
