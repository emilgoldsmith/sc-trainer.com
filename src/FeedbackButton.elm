module FeedbackButton exposing (overlay)

import Css exposing (testid)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import ViewportSize exposing (ViewportSize)


overlay : ViewportSize -> Attribute msg
overlay viewportSize =
    inFront <|
        el
            [ alignBottom
            , alignRight
            , padding (ViewportSize.minDimension viewportSize // 30)
            ]
        <|
            newTabLink
                [ testid "feedback-button"
                , Background.color (rgb255 208 211 207)
                , padding (ViewportSize.minDimension viewportSize // 45)
                , Border.rounded (ViewportSize.minDimension viewportSize // 30)
                , Border.width (ViewportSize.minDimension viewportSize // 250)
                , Border.color (rgb255 0 0 0)
                , Font.size (ViewportSize.minDimension viewportSize // 25)
                ]
                { url = "https://forms.gle/ftCX7eoT71g8f5ob6", label = text "Give Feedback" }
