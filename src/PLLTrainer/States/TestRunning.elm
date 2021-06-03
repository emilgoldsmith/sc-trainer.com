module PLLTrainer.States.TestRunning exposing (state)

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
view _ =
    { topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            Element.none
    }
