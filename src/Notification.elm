module Notification exposing (Type(..), overlay)

import Css exposing (testid)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Html.Events
import Json.Decode
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated
import Simple.Animation.Property
import UI exposing (Palette)
import ViewportSize exposing (ViewportSize)


type Type
    = Success
    | Error
    | Message


overlay :
    ViewportSize
    -> Palette
    ->
        { message : String
        , notificationType : Type
        , onReadyToDelete : msg
        , animationOverrides :
            Maybe
                { entryExitTimeMs : Int
                , notificationDisplayTimeMs : Int
                }
        }
    -> Attribute msg
overlay viewportSize palette { message, notificationType, onReadyToDelete, animationOverrides } =
    let
        maxWidth =
            ViewportSize.width viewportSize * 7 // 10

        ( backgroundColor, notificationTestId ) =
            case notificationType of
                Error ->
                    ( palette.error, "error-notification" )

                Success ->
                    ( palette.correct, "success-notification" )

                Message ->
                    ( palette.greyBackground, "message-notification" )

        animationParams =
            animationOverrides
                |> Maybe.withDefault { entryExitTimeMs = 1000, notificationDisplayTimeMs = 5000 }
    in
    inFront <|
        animatedUi el
            (enterAndExitAnimation animationParams)
            [ testid "notification-container"
            , testid notificationTestId
            , alignTop
            , centerX
            , Background.color backgroundColor
            , Font.color palette.darkText
            , UI.paddingAll.veryLarge
            , UI.fontSize.large
            , width (shrink |> maximum maxWidth)
            , htmlAttribute <| Html.Events.on "animationend" (Json.Decode.succeed onReadyToDelete)
            ]
        <|
            paragraph
                [ centerX
                , centerY
                ]
                [ text message ]


animatedUi :
    (List (Attribute msg) -> children -> Element msg)
    -> Animation
    -> List (Attribute msg)
    -> children
    -> Element msg
animatedUi =
    Simple.Animation.Animated.ui
        { behindContent = behindContent
        , htmlAttribute = htmlAttribute
        , html = html
        }


transform : String -> Simple.Animation.Property.Property
transform =
    Simple.Animation.Property.property "transform"


enterAndExitAnimation :
    { entryExitTimeMs : Int, notificationDisplayTimeMs : Int }
    -> Animation
enterAndExitAnimation { entryExitTimeMs, notificationDisplayTimeMs } =
    Animation.steps
        { startAt = [ transform "translateY(-100%)" ]
        , options = [ Animation.easeInOutQuad ]
        }
        [ Animation.step entryExitTimeMs [ transform "translateY(0)" ]
        , Animation.wait notificationDisplayTimeMs
        , Animation.step entryExitTimeMs [ transform "translateY(-100%)" ]
        ]
