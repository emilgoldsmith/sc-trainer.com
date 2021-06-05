module PLLTrainer.State exposing (State, View, element, stateViewToGlobalView, static)

import Browser.Events
import Json.Decode
import Key exposing (Key)
import View


type alias View msg =
    { topLevelEventListeners : View.TopLevelEventListeners msg
    , overlays : View.Overlays msg
    , body : View.Body msg
    }


type alias State msg localMsg model =
    { init : ( model, Cmd msg )
    , update : localMsg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> View msg
    }


static :
    { nonRepeatedKeyUpHandler : Maybe (Key -> msg)
    , view : View msg
    }
    -> State msg () ()
static { nonRepeatedKeyUpHandler, view } =
    let
        subscription =
            Maybe.withDefault Sub.none <|
                Maybe.map
                    (\handler ->
                        Browser.Events.onKeyUp <|
                            Json.Decode.map
                                handler
                                Key.decodeNonRepeatedKeyEvent
                    )
                    nonRepeatedKeyUpHandler
    in
    { init = ( (), Cmd.none )
    , update = always <| always ( (), Cmd.none )
    , subscriptions = always subscription
    , view = always view
    }


element :
    { init : ( model, Cmd msg )
    , update : localMsg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> View msg
    }
    -> State msg localMsg model
element =
    identity


stateViewToGlobalView : Maybe String -> View a -> View.View a
stateViewToGlobalView pageSubtitle { topLevelEventListeners, overlays, body } =
    { topLevelEventListeners = topLevelEventListeners, overlays = overlays, body = body, pageSubtitle = pageSubtitle }
