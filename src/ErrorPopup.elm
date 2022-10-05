module ErrorPopup exposing (overlay)

import Css exposing (errorMessageTestType, testid)
import Element exposing (..)
import ViewportSize exposing (ViewportSize)


overlay :
    ViewportSize
    -> Attribute msg
overlay viewportSize =
    inFront <|
        el
            [ alignBottom
            , alignRight
            , padding (ViewportSize.minDimension viewportSize // 30)
            ]
        <|
            el
                [ testid "error-popup"
                , errorMessageTestType
                ]
            <|
                text "temp"
