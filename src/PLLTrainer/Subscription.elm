module PLLTrainer.Subscription exposing (Subscription(..), getSub, getTopLevelEventListeners)

import Element


type Subscription msg
    = BrowserEvents (Sub msg)
    | ElementAttributes (List (Element.Attribute msg))
    | BothSubscriptions
        { browserEvents : Sub msg
        , elementAttributes : List (Element.Attribute msg)
        }


getSub : Subscription msg -> Sub msg
getSub sub =
    case sub of
        BrowserEvents browserEvents ->
            browserEvents

        ElementAttributes _ ->
            Sub.none

        BothSubscriptions { browserEvents } ->
            browserEvents


getTopLevelEventListeners : Subscription msg -> List (Element.Attribute msg)
getTopLevelEventListeners sub =
    case sub of
        BrowserEvents _ ->
            []

        ElementAttributes elementAttributes ->
            elementAttributes

        BothSubscriptions { elementAttributes } ->
            elementAttributes
