module PLLTrainer.States.GetReadyScreen exposing (state)

import Element exposing (..)
import Element.Font as Font
import Shared
import StatefulPage
import UI
import Utils.Css exposing (testid)
import View
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> StatefulPage.StateView msg
state { viewportSize } =
    view viewportSize


view : ViewportSize -> StatefulPage.StateView msg
view viewportSize =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            el
                [ testid "get-ready-container"
                , centerX
                , centerY
                ]
            <|
                paragraph
                    [ testid "get-ready-explanation"
                    , Font.size (ViewportSize.minDimension viewportSize * 2 // 9)
                    , Font.center
                    , UI.paddingAll.medium
                    ]
                    [ text "Go To Home Grip" ]
    }
