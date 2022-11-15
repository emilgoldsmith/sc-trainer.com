module View exposing
    ( Body
    , Overlays
    , TopLevelEventListeners
    , View
    , addOverlays
    , buildOverlays
    , buildTopLevelEventListeners
    , customBody
    , fullScreenBody
    , fullScreenScrollableContainerId
    , map
    , none
    , placeholder
    , toBrowserDocument
    , withNavigationBody
    )

import Browser
import Element exposing (Element)


type alias View msg =
    { pageSubtitle : Maybe String
    , topLevelEventListeners : TopLevelEventListeners msg
    , overlays : Overlays msg
    , extraTopLevelAttributes : List (Element.Attribute msg)
    , body : Body msg
    }


type Body msg
    = FullScreen (Element msg)
    | WithNavigation (Element msg)
    | Custom (Element msg)


fullScreenScrollableContainerId : String
fullScreenScrollableContainerId =
    "full-screen-scrollable-container"


fullScreenBody : ({ scrollableContainerId : String } -> Element msg) -> Body msg
fullScreenBody f =
    FullScreen (f { scrollableContainerId = fullScreenScrollableContainerId })


withNavigationBody : Element msg -> Body msg
withNavigationBody =
    WithNavigation


customBody : Element msg -> Body msg
customBody =
    Custom


mapBody : (a -> b) -> Body a -> Body b
mapBody fn body =
    case body of
        FullScreen element ->
            FullScreen <| Element.map fn element

        WithNavigation element ->
            WithNavigation <| Element.map fn element

        Custom element ->
            Custom <| Element.map fn element


type TopLevelEventListeners msg
    = TopLevelEventListeners (List (Element.Attribute msg))


buildTopLevelEventListeners : List (Element.Attribute msg) -> TopLevelEventListeners msg
buildTopLevelEventListeners =
    TopLevelEventListeners


mapTopLevelEventListeners : (a -> b) -> TopLevelEventListeners a -> TopLevelEventListeners b
mapTopLevelEventListeners fn (TopLevelEventListeners listeners) =
    buildTopLevelEventListeners <| List.map (Element.mapAttribute fn) listeners


topLevelEventListenersToElement : TopLevelEventListeners msg -> List (Element.Attribute msg)
topLevelEventListenersToElement (TopLevelEventListeners listeners) =
    listeners


type Overlays msg
    = Overlays (List (Element.Attribute msg))


addOverlays : List (Element.Attribute msg) -> View msg -> View msg
addOverlays newOverlayElements view =
    let
        (Overlays oldOverlayElements) =
            view.overlays
    in
    { view
        | overlays = Overlays <| oldOverlayElements ++ newOverlayElements
    }


buildOverlays : List (Element.Attribute msg) -> Overlays msg
buildOverlays =
    Overlays


mapOverlays : (a -> b) -> Overlays a -> Overlays b
mapOverlays fn (Overlays overlays) =
    buildOverlays <| List.map (Element.mapAttribute fn) overlays


overlaysToElement : Overlays msg -> List (Element.Attribute msg)
overlaysToElement (Overlays overlays) =
    overlays


placeholder : String -> View msg
placeholder pageName =
    { pageSubtitle = Just pageName
    , topLevelEventListeners = buildTopLevelEventListeners []
    , overlays = buildOverlays []
    , extraTopLevelAttributes = []
    , body = WithNavigation <| Element.text pageName
    }


none : View msg
none =
    { pageSubtitle = Nothing
    , topLevelEventListeners = buildTopLevelEventListeners []
    , overlays = buildOverlays []
    , extraTopLevelAttributes = []
    , body = Custom Element.none
    }


map : (a -> b) -> View a -> View b
map fn { pageSubtitle, body, topLevelEventListeners, extraTopLevelAttributes, overlays } =
    { pageSubtitle = pageSubtitle
    , topLevelEventListeners = mapTopLevelEventListeners fn topLevelEventListeners
    , overlays = mapOverlays fn overlays
    , extraTopLevelAttributes = List.map (Element.mapAttribute fn) extraTopLevelAttributes
    , body = mapBody fn body
    }


toBrowserDocument : View msg -> Browser.Document msg
toBrowserDocument { pageSubtitle, body, topLevelEventListeners, extraTopLevelAttributes, overlays } =
    let
        appTitle =
            "Speedcubing Trainer"

        topLevelAttributes =
            topLevelEventListenersToElement topLevelEventListeners
                ++ overlaysToElement overlays
                ++ extraTopLevelAttributes
    in
    { title =
        Maybe.map
            (\a -> String.trim a ++ " | " ++ appTitle)
            pageSubtitle
            |> Maybe.withDefault appTitle
    , body =
        List.singleton <|
            case body of
                FullScreen element ->
                    Element.layout topLevelAttributes element

                WithNavigation element ->
                    Element.layout topLevelAttributes element

                Custom element ->
                    Element.layout topLevelAttributes element
    }
