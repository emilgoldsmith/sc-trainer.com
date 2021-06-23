module Shared exposing
    ( Flags
    , HardwareAvailable
    , Model
    , Msg
    , PublicMsg(..)
    , buildSharedMessage
    , init
    , subscriptions
    , update
    )

import Algorithm exposing (Algorithm)
import Browser.Events as Events
import Json.Decode
import PLL exposing (PLL)
import Ports
import Request exposing (Request)
import UI
import User exposing (User)
import ViewportSize exposing (ViewportSize)



-- Flags


type alias Flags =
    { viewportSize : { width : Int, height : Int }
    , touchScreenAvailable : Bool
    , featureFlags : FeatureFlags
    , storedUser : Json.Decode.Value
    }


type alias FeatureFlags =
    { displayAlgorithmPicker : Bool
    }



-- INIT


type alias Model =
    { viewportSize : ViewportSize
    , hardwareAvailable : HardwareAvailable
    , palette : UI.Palette
    , featureFlags : FeatureFlags
    , user : User
    }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ { viewportSize, touchScreenAvailable, featureFlags, storedUser } =
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

                -- We don't know from the beginning if there is a keyboard so
                -- we tell the guess function that we don't know there is one
                -- for sure
                , keyboard = False
                }
      , featureFlags = featureFlags
      , user = User.deserialize storedUser |> Result.withDefault User.new
      }
    , Cmd.none
    )


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



-- UPDATE


type Msg
    = InternalMsg InternalMsg
    | PublicMsg PublicMsg


buildSharedMessage : PublicMsg -> Msg
buildSharedMessage =
    PublicMsg


type InternalMsg
    = WindowResized Int Int
    | KeyboardWasUsed


type PublicMsg
    = ChangePLLAlgorithm PLL Algorithm


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        InternalMsg internalMsg ->
            case internalMsg of
                WindowResized width height ->
                    let
                        newViewportSize =
                            ViewportSize.build { width = width, height = height }
                    in
                    ( { model
                        | hardwareAvailable = guessIfUserHasKeyboard newViewportSize model.hardwareAvailable
                        , viewportSize = newViewportSize
                      }
                    , Cmd.none
                    )

                KeyboardWasUsed ->
                    ( { model
                        | hardwareAvailable = setKeyboardAvailable model.hardwareAvailable
                      }
                    , Cmd.none
                    )

        PublicMsg publicMsg ->
            case publicMsg of
                ChangePLLAlgorithm pll algorithm ->
                    let
                        updatedUser =
                            User.changePLLAlgorithm pll algorithm model.user
                    in
                    ( { model | user = updatedUser }
                    , Ports.updateStoredUser updatedUser
                    )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ model =
    Sub.map InternalMsg <|
        Sub.batch
            [ Events.onResize WindowResized
            , if model.hardwareAvailable.keyboard then
                Sub.none

              else
                Sub.batch
                    [ Events.onKeyDown (Json.Decode.succeed KeyboardWasUsed)
                    , Events.onKeyPress (Json.Decode.succeed KeyboardWasUsed)
                    , Events.onKeyUp (Json.Decode.succeed KeyboardWasUsed)
                    ]
            ]
