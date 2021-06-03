module StatefulPage exposing (Msg(..), State, StateView, getSubscriptions, getView, static, toView)

import Shared exposing (subscriptions)
import View exposing (View)


type State transition
    = Internal { view : StateView (Msg transition), subscriptions : Sub (Msg transition) }


type Msg transition
    = TransitionMsg transition


getView : State transition -> StateView (Msg transition)
getView (Internal { view }) =
    view


getSubscriptions : State transition -> Sub (Msg transition)
getSubscriptions (Internal { subscriptions }) =
    subscriptions


type alias StateView msg =
    { topLevelEventListeners : View.TopLevelEventListeners msg
    , overlays : View.Overlays msg
    , body : View.Body msg
    }


mapStateView : (a -> b) -> StateView a -> StateView b
mapStateView fn =
    toView Nothing >> View.map fn >> toStateView


toView : Maybe String -> StateView a -> View a
toView pageSubtitle { topLevelEventListeners, overlays, body } =
    { topLevelEventListeners = topLevelEventListeners, overlays = overlays, body = body, pageSubtitle = pageSubtitle }


toStateView : View a -> StateView a
toStateView { topLevelEventListeners, overlays, body } =
    { topLevelEventListeners = topLevelEventListeners, overlays = overlays, body = body }


static :
    { view : StateView transition
    , subscriptions : Sub transition
    }
    -> State transition
static { view, subscriptions } =
    Internal
        { view = mapStateView TransitionMsg view
        , subscriptions = Sub.map TransitionMsg subscriptions
        }
