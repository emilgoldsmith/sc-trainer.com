module Main exposing (main)

import Browser
import Element exposing (..)

view : Model -> Browser.Document Msg
view model =
    { title = "PLL | Speedcubing Trainer"
    , body =
        [ layout
            [ inFront (viewFullScreen model) ]
            (viewState model)
        ]
    }


viewFullScreen : Model -> Element msg
viewFullScreen _ =
    none


viewState : Model -> Element msg
viewState _ =
    none
