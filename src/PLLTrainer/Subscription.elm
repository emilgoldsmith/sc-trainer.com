module PLLTrainer.Subscription exposing (Subscription, browserEventsAndElementAttributes, getSub, getTopLevelEventListeners, none, onlyBrowserEvents, onlyElementAttributes)

import Element


type Subscription msg
    = BrowserEvents (Sub msg)
    | ElementAttributes (List (Element.Attribute msg))
    | BothSubscriptions
        { browserEvents : Sub msg
        , elementAttributes : List (Element.Attribute msg)
        }


none : Subscription msg
none =
    BrowserEvents Sub.none


onlyBrowserEvents : Sub msg -> Subscription msg
onlyBrowserEvents =
    BrowserEvents


onlyElementAttributes : List (Element.Attribute msg) -> Subscription msg
onlyElementAttributes =
    ElementAttributes


browserEventsAndElementAttributes :
    { browserEvents : Sub msg
    , elementAttributes : List (Element.Attribute msg)
    }
    -> Subscription msg
browserEventsAndElementAttributes =
    BothSubscriptions


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
