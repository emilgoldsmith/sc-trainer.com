module View exposing (Body(..), View, map, none, placeholder, toBrowserDocument)

import Browser
import Element exposing (Element)


type alias View msg =
    { pageSubtitle : Maybe String
    , body : Body msg
    , topLevelEventListeners : List (Element.Attribute msg)
    }


type Body msg
    = FullScreen (Element msg)
    | WithNavigation (Element msg)
    | Custom (Element msg)


mapBody : (a -> b) -> Body a -> Body b
mapBody fn body =
    case body of
        FullScreen element ->
            FullScreen <| Element.map fn element

        WithNavigation element ->
            WithNavigation <| Element.map fn element

        Custom element ->
            Custom <| Element.map fn element


placeholder : String -> View msg
placeholder pageName =
    { pageSubtitle = Just pageName
    , body = WithNavigation <| Element.text pageName
    , topLevelEventListeners = []
    }


none : View msg
none =
    { pageSubtitle = Nothing
    , body = Custom Element.none
    , topLevelEventListeners = []
    }


map : (a -> b) -> View a -> View b
map fn { pageSubtitle, body, topLevelEventListeners } =
    { pageSubtitle = pageSubtitle
    , body = mapBody fn body
    , topLevelEventListeners = List.map (Element.mapAttribute fn) topLevelEventListeners
    }


toBrowserDocument : View msg -> Browser.Document msg
toBrowserDocument { pageSubtitle, body, topLevelEventListeners } =
    let
        appTitle =
            "Speedcubing Trainer"
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
                    Element.layout (Element.inFront element :: topLevelEventListeners) Element.none

                WithNavigation element ->
                    Element.layout topLevelEventListeners element

                Custom element ->
                    Element.layout topLevelEventListeners element
    }
