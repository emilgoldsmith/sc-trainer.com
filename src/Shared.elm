module Shared exposing
    ( CubeViewOptions
    , FeatureFlags
    , Flags
    , HardwareAvailable
    , Model
    , Msg
    , PublicMsg(..)
    , buildSharedMessage
    , getDisplayAngleOverride
    , getDisplayCubeAnnotationsOverride
    , getGlobalOverlays
    , getSizeOverride
    , init
    , shouldUseDebugViewForVisualTesting
    , subscriptions
    , update
    )

import Browser.Events as Events
import Cube
import Element
import ErrorMessage
import Json.Decode
import Key
import Notification
import Ports
import Process
import Request exposing (Request)
import Task
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
        }
    }


type alias FeatureFlags =
    {}


type CubeViewOptions
    = CubeViewOptions
        { useDebugViewForVisualTesting : Bool
        , displayAngleOverride : Maybe Cube.DisplayAngle
        , sizeOverride : Maybe Int
        , displayCubeAnnotationsOverride : Maybe Bool
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


getDisplayCubeAnnotationsOverride : CubeViewOptions -> Maybe Bool
getDisplayCubeAnnotationsOverride (CubeViewOptions { displayCubeAnnotationsOverride }) =
    displayCubeAnnotationsOverride



-- INIT


type alias Model =
    { viewportSize : ViewportSize
    , hardwareAvailable : HardwareAvailable
    , palette : UI.Palette
    , featureFlags : FeatureFlags
    , user : User
    , cubeViewOptions : CubeViewOptions
    , errorMessages :
        List
            { userFacingErrorMessage : String
            , developerErrorMessage : String
            , uniqueId : Int
            }
    , nextUnusedErrorMessageId : Int
    , notificationQueue : List { message : String, notificationType : Notification.Type }
    , currentNotification : Maybe { message : String, notificationType : Notification.Type }
    , notificationQueueActive : Bool
    }


init : Request -> Flags -> ( Model, Cmd Msg )
init _ { viewportSize, touchScreenAvailable, featureFlags, storedUser, cubeViewOptions } =
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
      , user = User.deserialize storedUser |> Result.withDefault User.new
      , featureFlags = featureFlags
      , cubeViewOptions =
            CubeViewOptions
                { useDebugViewForVisualTesting = cubeViewOptions.useDebugViewForVisualTesting
                , displayAngleOverride = Nothing
                , sizeOverride = Nothing
                , displayCubeAnnotationsOverride = Nothing
                }
      , errorMessages = []
      , nextUnusedErrorMessageId = 0
      , notificationQueue = []
      , currentNotification = Nothing
      , notificationQueueActive = False
      }
    , Cmd.none
    )


getGlobalOverlays : Model -> List (Element.Attribute Msg)
getGlobalOverlays shared =
    (shared.errorMessages
        |> List.map
            (\{ userFacingErrorMessage, developerErrorMessage, uniqueId } ->
                ErrorMessage.popupOverlay
                    shared.viewportSize
                    shared.palette
                    { errorDescription = userFacingErrorMessage
                    , sendError =
                        InternalMsg <|
                            SendErrorPopup
                                { id = uniqueId
                                , errorMessage = developerErrorMessage
                                }
                    , closeWithoutSending =
                        InternalMsg <|
                            CancelErrorPopup { id = uniqueId }
                    }
            )
    )
        ++ (shared.currentNotification
                |> Maybe.map
                    (\notificationParams ->
                        Notification.overlay
                            shared.viewportSize
                            shared.palette
                            { message = notificationParams.message
                            , notificationType = notificationParams.notificationType
                            , onReadyToDelete = InternalMsg HandleNotificationDone
                            , animationOverrides = Nothing
                            }
                    )
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
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
    | CancelErrorPopup { id : Int }
    | SendErrorPopup { id : Int, errorMessage : String }
    | HandleNotificationDone
    | DisplayNextNotification
    | NoOp


type PublicMsg
    = ModifyUser (User -> ( User, Maybe { errorMessage : String } ))
    | AddErrorPopup
        { userFacingErrorMessage : String
        , developerErrorMessage : String
        }
    | AddNotification { message : String, notificationType : Notification.Type }
    | TESTONLYOverrideDisplayAngle (Maybe Cube.DisplayAngle)
    | TESTONLYSetCubeSizeOverride (Maybe Int)
    | TESTONLYOverrideDisplayCubeAnnotations (Maybe Bool)


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

                CancelErrorPopup { id } ->
                    ( { model
                        | errorMessages =
                            model.errorMessages
                                |> List.filter (\{ uniqueId } -> uniqueId /= id)
                      }
                    , Cmd.none
                    )

                SendErrorPopup { id, errorMessage } ->
                    ( { model
                        | errorMessages =
                            model.errorMessages
                                |> List.filter (\{ uniqueId } -> uniqueId /= id)
                      }
                    , Ports.logError errorMessage
                    )

                HandleNotificationDone ->
                    if List.isEmpty model.notificationQueue then
                        ( { model
                            | currentNotification = Nothing
                            , notificationQueueActive = False
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | currentNotification = Nothing
                          }
                        , Task.perform (always <| InternalMsg DisplayNextNotification) <| Process.sleep 100
                        )

                DisplayNextNotification ->
                    ( { model
                        | notificationQueue = List.drop 1 model.notificationQueue
                        , currentNotification = List.head model.notificationQueue
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

                AddErrorPopup args ->
                    ( { model
                        | errorMessages =
                            { developerErrorMessage = args.developerErrorMessage
                            , userFacingErrorMessage = args.userFacingErrorMessage
                            , uniqueId = model.nextUnusedErrorMessageId
                            }
                                :: model.errorMessages
                        , nextUnusedErrorMessageId = model.nextUnusedErrorMessageId + 1
                      }
                    , Cmd.none
                    )

                AddNotification notificationParams ->
                    if model.notificationQueueActive then
                        ( { model
                            | notificationQueue = model.notificationQueue ++ [ notificationParams ]
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | currentNotification = Just notificationParams
                            , notificationQueueActive = True
                          }
                        , Cmd.none
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

                TESTONLYOverrideDisplayCubeAnnotations displayAnnotations ->
                    let
                        (CubeViewOptions cubeViewOptionsRecord) =
                            model.cubeViewOptions

                        newCubeViewOptions =
                            CubeViewOptions
                                { cubeViewOptionsRecord
                                    | displayCubeAnnotationsOverride = displayAnnotations
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
