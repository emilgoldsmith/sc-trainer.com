module Shared exposing
    ( CubeViewOptions
    , Flags
    , HardwareAvailable
    , Model
    , Msg
    , PublicMsg(..)
    , buildSharedMessage
    , getDisplayAngleOverride
    , getSizeOverride
    , init
    , shouldUseDebugViewForVisualTesting
    , subscriptions
    , update
    )

import Browser.Events as Events
import Cube
import Json.Decode
import Key
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
    , cubeViewOptions :
        { useDebugViewForVisualTesting : Bool
        , displayAngleOverride : Maybe String
        , sizeOverride : Maybe Int
        }
    }


type alias FeatureFlags =
    {}


type CubeViewOptions
    = CubeViewOptions
        { useDebugViewForVisualTesting : Bool
        , displayAngleOverride : Maybe Cube.DisplayAngle
        , sizeOverride : Maybe Int
        }


shouldUseDebugViewForVisualTesting : CubeViewOptions -> Bool
shouldUseDebugViewForVisualTesting (CubeViewOptions { useDebugViewForVisualTesting }) =
    useDebugViewForVisualTesting


getDisplayAngleOverride : CubeViewOptions -> Maybe Cube.DisplayAngle
getDisplayAngleOverride (CubeViewOptions { displayAngleOverride }) =
    displayAngleOverride


getSizeOverride : CubeViewOptions -> Maybe Int
getSizeOverride (CubeViewOptions { sizeOverride }) =
    sizeOverride



-- INIT


type alias Model =
    { viewportSize : ViewportSize
    , hardwareAvailable : HardwareAvailable
    , palette : UI.Palette
    , featureFlags : FeatureFlags
    , user : User
    , cubeViewOptions : CubeViewOptions
    }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ { viewportSize, touchScreenAvailable, featureFlags, storedUser, cubeViewOptions } =
    let
        builtViewportSize =
            ViewportSize.build viewportSize

        ( displayAngleOverride, cmd ) =
            case Maybe.map String.toLower cubeViewOptions.displayAngleOverride of
                Nothing ->
                    ( Nothing, Cmd.none )

                Just "ufr" ->
                    ( Just Cube.ufrDisplayAngle, Cmd.none )

                Just "ubl" ->
                    ( Just Cube.ublDisplayAngle, Cmd.none )

                Just "dbl" ->
                    ( Just Cube.dblDisplayAngle, Cmd.none )

                Just displayAngleString ->
                    ( Nothing
                    , Ports.logError
                        ("unsupported display angle in displayAngleOverride flag: " ++ displayAngleString)
                    )
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
      , user = User.deserialize storedUser |> Result.withDefault User.new
      , featureFlags = featureFlags
      , cubeViewOptions =
            CubeViewOptions
                { useDebugViewForVisualTesting = cubeViewOptions.useDebugViewForVisualTesting
                , displayAngleOverride = displayAngleOverride
                , sizeOverride = cubeViewOptions.sizeOverride
                }
      }
    , cmd
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
    | NoOp


type PublicMsg
    = ModifyUser (User -> ( User, Maybe { errorMessage : String } ))
    | TESTONLYOverrideDisplayAngle (Maybe Cube.DisplayAngle)
    | TESTONLYSetCubeSizeOverride (Maybe Int)


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

                NoOp ->
                    ( model, Cmd.none )

        PublicMsg publicMsg ->
            case publicMsg of
                ModifyUser getNewUser ->
                    getNewUser model.user
                        |> Tuple.mapFirst
                            (\user -> { model | user = user })
                        |> Tuple.mapSecond
                            (Maybe.map (.errorMessage >> Ports.logError)
                                >> Maybe.withDefault Cmd.none
                            )
                        |> (\( newModel, cmd ) ->
                                ( newModel
                                , Cmd.batch [ cmd, Ports.updateStoredUser newModel.user ]
                                )
                           )

                TESTONLYOverrideDisplayAngle newDisplayAngle ->
                    let
                        (CubeViewOptions cubeViewOptionsRecord) =
                            model.cubeViewOptions

                        newCubeViewOptions =
                            CubeViewOptions
                                { cubeViewOptionsRecord
                                    | displayAngleOverride = newDisplayAngle
                                }
                    in
                    ( { model | cubeViewOptions = newCubeViewOptions }, Cmd.none )

                TESTONLYSetCubeSizeOverride size ->
                    let
                        (CubeViewOptions cubeViewOptionsRecord) =
                            model.cubeViewOptions

                        newCubeViewOptions =
                            CubeViewOptions
                                { cubeViewOptionsRecord
                                    | sizeOverride = size
                                }
                    in
                    ( { model | cubeViewOptions = newCubeViewOptions }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ model =
    Sub.map InternalMsg <|
        Sub.batch
            [ Events.onResize WindowResized
            , if model.hardwareAvailable.keyboard then
                Sub.none

              else
                Sub.batch <|
                    ([ Events.onKeyDown, Events.onKeyPress, Events.onKeyUp ]
                        |> List.map
                            (\x ->
                                x <|
                                    Json.Decode.map
                                        (\target ->
                                            if target == "INPUT" then
                                                NoOp

                                            else
                                                KeyboardWasUsed
                                        )
                                        Key.decodeKeyEventTargetNodeName
                            )
                    )
            ]
