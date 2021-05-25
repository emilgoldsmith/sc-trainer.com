module View exposing (View, map, none, placeholder, toBrowserDocument)

import Browser
import Element exposing (Element)


type alias View msg =
    { pageSubtitle : Maybe String
    , element : Element msg
    }


placeholder : String -> View msg
placeholder pageName =
    { pageSubtitle = Just pageName
    , element = Element.text pageName
    }


none : View msg
none =
    { pageSubtitle = Nothing
    , element = Element.none
    }


map : (a -> b) -> View a -> View b
map fn view =
    { pageSubtitle = view.pageSubtitle
    , element = Element.map fn view.element
    }


toBrowserDocument : View msg -> Browser.Document msg
toBrowserDocument view =
    let
        appTitle =
            "Speedcubing Trainer"
    in
    { title =
        Maybe.map
            (\a -> String.trim a ++ " | " ++ appTitle)
            view.pageSubtitle
            |> Maybe.withDefault appTitle
    , body = [ Element.layout [] view.element ]
    }
