module PLLTrainer.State exposing (State, View, element, sandbox, stateViewToGlobalView, static)

import Browser.Events
import Element
import Json.Decode
import Key exposing (Key)
import PLLTrainer.Subscription
import View


type alias View msg =
    { overlays : View.Overlays msg
    , body : View.Body msg
    }


type alias State msg localMsg model =
    { init : ( model, Cmd msg )
    , update : localMsg -> model -> ( model, Cmd msg )
    , subscriptions : model -> PLLTrainer.Subscription.Subscription msg
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
            PLLTrainer.Subscription.onlyBrowserEvents <|
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


sandbox :
    { nonRepeatedKeyUpHandler : Maybe (Key -> msg)
    , init : model
    , view : model -> View msg
    , update : localMsg -> model -> model
    }
    -> State msg localMsg model
sandbox { nonRepeatedKeyUpHandler, init, view, update } =
    let
        subscription =
            PLLTrainer.Subscription.onlyBrowserEvents <|
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
    { init = ( init, Cmd.none )
    , update = \msg model -> ( update msg model, Cmd.none )
    , subscriptions = always subscription
    , view = view
    }


element :
    { init : ( model, Cmd msg )
    , update : localMsg -> model -> ( model, Cmd msg )
    , subscriptions : model -> PLLTrainer.Subscription.Subscription msg
    , view : model -> View msg
    }
    -> State msg localMsg model
element =
    identity


stateViewToGlobalView : Maybe String -> PLLTrainer.Subscription.Subscription msg -> List (Element.Attribute msg) -> View msg -> View.View msg
stateViewToGlobalView pageSubtitle subscription extraTopLevelAttributes { overlays, body } =
    { topLevelEventListeners =
        View.buildTopLevelEventListeners <|
            PLLTrainer.Subscription.getTopLevelEventListeners subscription
    , overlays = overlays
    , extraTopLevelAttributes = extraTopLevelAttributes
    , body = body
    , pageSubtitle = pageSubtitle
    }
