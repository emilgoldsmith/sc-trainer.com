module Pages.UnexposedInternalRoutes.ComponentTests.NotificationTest exposing (Model, Msg, page)

import Css exposing (testid)
import Element exposing (..)
import Element.Input
import Gen.Params.UnexposedInternalRoutes.ComponentTests.ErrorPopupTest exposing (Params)
import Notification
import Page
import Process
import Request
import Shared
import Task
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init
        , update = update
        , view = view shared
        , subscriptions = always Sub.none
        }


type alias Model =
    { notificationQueue : List Notification.Type
    , currentNotification : Maybe Notification.Type
    , notificationDisplayTimeMs : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { notificationQueue = []
      , currentNotification = Nothing
      , notificationDisplayTimeMs = 5000
      }
    , Cmd.none
    )


type Msg
    = DisplayOnlyErrorNotification
    | DisplayOnlySuccessNotification
    | DisplayOnlyMessageNotification
    | InitiateAllNotificationsInSeries
    | HandleNotificationDone
    | DisplayNextNotification


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DisplayOnlyErrorNotification ->
            ( { model
                | notificationQueue = []
                , currentNotification = Just Notification.Error
                , notificationDisplayTimeMs = 5000
              }
            , Cmd.none
            )

        DisplayOnlySuccessNotification ->
            ( { model
                | notificationQueue = []
                , currentNotification = Just Notification.Success
                , notificationDisplayTimeMs = 5000
              }
            , Cmd.none
            )

        DisplayOnlyMessageNotification ->
            ( { model
                | notificationQueue = []
                , currentNotification =
                    Just Notification.Message
                , notificationDisplayTimeMs = 5000
              }
            , Cmd.none
            )

        InitiateAllNotificationsInSeries ->
            ( { model
                | notificationQueue =
                    [ Notification.Error
                    , Notification.Success
                    , Notification.Message
                    ]
                , currentNotification = Nothing
                , notificationDisplayTimeMs = 100
              }
            , Task.perform (always DisplayNextNotification) <| Process.sleep 100
            )

        HandleNotificationDone ->
            ( { model
                | currentNotification = Nothing
              }
            , Task.perform (always DisplayNextNotification) <| Process.sleep 100
            )

        DisplayNextNotification ->
            ( { model
                | notificationQueue = List.drop 1 model.notificationQueue
                , currentNotification = List.head model.notificationQueue
              }
            , Cmd.none
            )


view : Shared.Model -> Model -> View Msg
view shared model =
    { pageSubtitle = Just "Notification Component Test"
    , topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays =
        model.currentNotification
            |> Maybe.map
                (\notificationType ->
                    View.buildOverlays
                        [ Notification.overlay
                            shared.viewportSize
                            shared.palette
                            { message = String.repeat 20 "lorem ipsum "
                            , notificationType = notificationType
                            , onReadyToDelete = HandleNotificationDone
                            , animationOverrides =
                                Just
                                    { entryExitTimeMs = 1
                                    , notificationDisplayTimeMs = model.notificationDisplayTimeMs
                                    }
                            }
                        ]
                )
            |> Maybe.withDefault (View.buildOverlays [])
    , extraTopLevelAttributes = []
    , body =
        View.fullScreenBody
            (\_ ->
                wrappedRow []
                    [ Element.Input.button [ testid "start-notification-series-button" ]
                        { onPress = Just InitiateAllNotificationsInSeries
                        , label = text "Start Notification Series"
                        }
                    , Element.Input.button [ testid "show-error-notification-button" ]
                        { onPress = Just DisplayOnlyErrorNotification
                        , label = text "Show Error Notification"
                        }
                    , Element.Input.button [ testid "show-success-notification-button" ]
                        { onPress = Just DisplayOnlySuccessNotification
                        , label = text "Show Success Notification"
                        }
                    , Element.Input.button [ testid "show-message-notification-button" ]
                        { onPress = Just DisplayOnlyMessageNotification
                        , label = text "Show Message Notification"
                        }
                    ]
            )
    }
