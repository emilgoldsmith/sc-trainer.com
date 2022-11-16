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
    { notificationQueue : List { notificationType : Notification.Type, testId : String }
    , currentNotification : Maybe { notificationType : Notification.Type, testId : String }
    }


init : ( Model, Cmd Msg )
init =
    ( { notificationQueue =
            [ { notificationType = Notification.Error, testId = "error-notification" }
            , { notificationType = Notification.Success, testId = "success-notification" }
            , { notificationType = Notification.Message, testId = "message-notification" }
            ]
      , currentNotification = Nothing
      }
    , Cmd.none
    )


type Msg
    = HandleNotificationDone
    | DisplayNextNotification


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                (\{ notificationType, testId } ->
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
                                    , notificationDisplayTimeMs = 100
                                    }
                            }
                            [ testid testId ]
                        ]
                )
            |> Maybe.withDefault (View.buildOverlays [])
    , extraTopLevelAttributes = []
    , body =
        View.fullScreenBody
            (\_ ->
                Element.Input.button [ testid "start-button" ]
                    { onPress = Just HandleNotificationDone
                    , label = text "Start"
                    }
            )
    }
