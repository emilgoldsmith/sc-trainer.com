module Main exposing (main)

import Browser
import Browser.Navigation
import Context
import Element exposing (..)
import PLLTrainer
import UI
import Url


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = always DoNothing
        , onUrlChange = always DoNothing
        }


init : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init ({ viewportSize, userHasTouchScreen } as flags) _ navigationKey =
    ( { context =
            Context.build
                { viewportSize = viewportSize
                , userHasKeyboard = guessIfUserHasKeyboard flags
                , userHasTouchScreen = userHasTouchScreen
                , navigationKey = navigationKey
                , palette = UI.defaultPalette
                }
      , pllTrainer = PLLTrainer.init
      }
    , Cmd.none
    )


type alias Flags =
    { viewportSize : { width : Int, height : Int }
    , userHasTouchScreen : Bool
    , featureFlags :
        { -- Placeholder is just here to silence linting errors for one field in a record
          -- as it makes sense here as feature flags will grow and shrink often.
          -- When we make the flag a Value input though we can maybe consider when there's one
          -- value just keeping it as a single one though
          placeholder : Bool
        , moreFlowWhenWrong : Bool
        }
    }


type alias Model =
    { context : Context.Context
    , pllTrainer : PLLTrainer.Model
    }


type Msg
    = ContextMessage Context.Msg
    | PLLTrainerMessage PLLTrainer.Msg
    | DoNothing


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update topLevelMessage model =
    ( model, Cmd.none )



-- case topLevelMessage of
--     GlobalMessage msg ->
--         let
--             newContext = case msg of
--                 WindowResized width height ->
--                     let
--                         modelWithUpdatedViewport =
--                             { model.context
--                                 | viewportSize = { width = width, height = height }
--                             }
--                     in
--                     { modelWithUpdatedViewport | userHasKeyboard = guessIfUserHasKeyboard modelWithUpdatedViewport }
--                 KeyboardWasUsed ->
--                     { model | userHasKeyboard = True }
--                 DoNothing ->
--                     model


view : Model -> Browser.Document Msg
view model =
    { title = "PLL | Speedcubing Trainer"
    , body =
        [ layout
            [ inFront (viewFullScreen model) ]
            (viewState model)
        ]
    }


viewFullScreen : Model -> Element msg
viewFullScreen _ =
    none


viewState : Model -> Element msg
viewState _ =
    none
