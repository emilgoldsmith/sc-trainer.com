module PLLTrainer.States.GetReadyScreen exposing (state)

import Css exposing (testid)
import Element exposing (..)
import Element.Font as Font
import PLLTrainer.State
import Shared
import UI
import View
import ViewportSize exposing (ViewportSize)


state : Shared.Model -> PLLTrainer.State.State msg () ()
state { viewportSize } =
    PLLTrainer.State.static
        { view = view viewportSize
        , nonRepeatedKeyUpHandler = Nothing
        }



-- VIEW


view : ViewportSize -> PLLTrainer.State.View msg
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
