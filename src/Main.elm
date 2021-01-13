module Main exposing (main)

import Components.Cube
import Html exposing (..)
import Models.Cube


main : Html Never
main =
    div [] [ Components.Cube.injectStyles, Components.Cube.view, Models.Cube.view ]
