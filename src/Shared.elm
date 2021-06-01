module Shared exposing
    ( Flags
    , HardwareAvailable
    , Model
    , Msg
    , init
    , subscriptions
    , update
    )

import Browser.Events as Events
import Json.Decode as Decode
import Request exposing (Request)
import UI
import ViewportSize exposing (ViewportSize)



-- Flags


type alias Flags =
    { viewportSize : { width : Int, height : Int }
    , touchScreenAvailable : Bool
    , featureFlags :
        { -- Placeholder is just here to silence linting errors for one field in a record
          -- as it makes sense here as feature flags will grow and shrink often.
          -- When we make the flag a Value input though we can maybe consider when there's one
          -- value just keeping it as a single one though
          placeholder : Bool
        , moreFlowWhenWrong : Bool
        }
    }



-- INIT


type alias Model =
    { viewportSize : ViewportSize
    , hardwareAvailable : HardwareAvailable
    , palette : UI.Palette
    }


type alias HardwareAvailable =
    { keyboard : Bool
    , touchScreen : Bool
    }


guessIfUserHasKeyboard : ViewportSize -> HardwareAvailable -> HardwareAvailable
guessIfUserHasKeyboard viewportSize available =
    { available
        | keyboard =
            available.keyboard
                || (let
                        isLargeScreen =
                            case ViewportSize.getDeviceClass viewportSize of
                                ViewportSize.Phone ->
                                    False

                                ViewportSize.Tablet ->
                                    False

                                ViewportSize.Desktop ->
                                    True

                                ViewportSize.BigDesktop ->
                                    True
                    in
                    -- Basically if there's no touch screen we assume they must have a keyboard.
                    -- If they do have a touch screen the best we can do is guess based on screen size
                    not available.touchScreen || isLargeScreen
                   )
    }


setKeyboardAvailable : HardwareAvailable -> HardwareAvailable
setKeyboardAvailable previous =
    { previous | keyboard = True }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ { viewportSize, touchScreenAvailable } =
    let
        builtViewportSize =
            ViewportSize.build viewportSize
    in
    ( { viewportSize = builtViewportSize
      , palette = UI.defaultPalette
      , hardwareAvailable =
            guessIfUserHasKeyboard
                builtViewportSize
                { touchScreen = touchScreenAvailable

                -- We don't know from the beginning if there is a keyboard so we make
                -- our guess from an assumption of no
                , keyboard = False
                }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = WindowResized Int Int
    | KeyboardWasUsed


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    Tuple.pair (updateModel msg model) Cmd.none


updateModel : Msg -> Model -> Model
updateModel msg model =
    case msg of
        WindowResized width height ->
            let
                newViewportSize =
                    ViewportSize.build { width = width, height = height }
            in
            { model
                | hardwareAvailable = guessIfUserHasKeyboard newViewportSize model.hardwareAvailable
                , viewportSize = newViewportSize
            }

        KeyboardWasUsed ->
            { model | hardwareAvailable = setKeyboardAvailable model.hardwareAvailable }



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ model =
    Sub.batch
        [ Events.onResize WindowResized
        , if model.hardwareAvailable.keyboard then
            Sub.none

          else
            Sub.batch
                [ Events.onKeyDown (Decode.succeed KeyboardWasUsed)
                , Events.onKeyPress (Decode.succeed KeyboardWasUsed)
                , Events.onKeyUp (Decode.succeed KeyboardWasUsed)
                ]
        ]
