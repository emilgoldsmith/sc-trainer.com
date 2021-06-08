module PLLTrainer.States.PickAlgorithmPage exposing (state)

import Css exposing (testid)
import Element exposing (..)
import PLLTrainer.State
import Shared
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
    { overlays = View.buildOverlays []
    , body =
        View.FullScreen <|
            el
                [ testid "pick-algorithm-container"
                , centerX
                , centerY
                ]
            <|
                text "Placeholder"
    }
