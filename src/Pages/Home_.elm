module Pages.Home_ exposing (Model, Msg, page)

import Gen.Params.Home_ exposing (Params)
import PLLTrainer.Page
import Page
import Request
import Shared


page : Shared.Model -> Request.With Params -> Page.With PLLTrainer.Page.Model PLLTrainer.Page.Msg
page shared _ =
    PLLTrainer.Page.page shared


type alias Msg =
    PLLTrainer.Page.Msg


type alias Model =
    PLLTrainer.Page.Model
