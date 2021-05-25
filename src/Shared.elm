module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    )

import Request exposing (Request)

-- Flags

type alias Flags =
    { viewportSize : { width : Int, height : Int }
    , userHasTouchScreen : Bool
    , featureFlags :
        { -- Placeholder is just here to silence linting errors for one field in a record
          -- as it makes sense here as feature flags will grow and shrink often.
          -- When we make the flag a Value input though we can maybe consider when there's one
          -- value just keeping it as a single one though
          placeholder : Bool
        , moreFlowWhenWrong : Bool
        }
    }

-- Model

type alias Model =
    { viewportSize : ViewportSize.ViewportSize
    , userHasKeyboard : Bool
    , userHasTouchScreen : Bool
    , palette : UI.Palette
    }

-- Init

init : Request -> Flags -> ( Model, Cmd Msg )
init _ ({ viewportSize, userHasTouchScreen } ) =
    let
        builtViewportSize = ViewportSize.build viewportSize
    in
    (
                { viewportSize = builtViewportSize
                , userHasKeyboard = guessIfUserHasKeyboard {userHasTouchScreen = userHasTouchScreen} builtViewportSize
                , userHasTouchScreen = userHasTouchScreen
                , palette = UI.defaultPalette
                }
      }
    , Cmd.none
    )

guessIfUserHasKeyboard : { a | userHasTouchScreen : Bool} -> ViewportSize -> Bool
guessIfUserHasKeyboard { userHasTouchScreen } viewportSize =
    let
        isLargeScreen =
            case ViewportSize.classifyDevice viewportSize |> .class of
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



-- Update

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
                            newViewportSize =ViewportSize.build {width = width, height = height}
                        in
                        { model |
                            userHasKeyboard = guessIfUserHasKeyboard model newViewportSize, viewportSize = newViewportSize}
                    KeyboardWasUsed ->
                        { model | userHasKeyboard = True }

-- Subscriptions

subscriptions : Request -> Model -> Sub Msg
subscriptions _ model =
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
