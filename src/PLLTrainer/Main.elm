module PLLTrainer.Main exposing (Model, Msg, page)

import Algorithm
import Cube exposing (Cube)
import PLL
import PLLTrainer.States.GetReadyScreen
import PLLTrainer.States.StartPage
import PLLTrainer.TestCase exposing (TestCase)
import Page
import Ports
import Shared
import StatefulPage
import View exposing (View)


page : Shared.Model -> Page.With Model Msg
page shared =
    Page.element
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions shared
        }


init : ( Model, Cmd Msg )
init =
    ( { trainerState = StartPage
      , expectedCubeState = Cube.solved

      -- This is just a placeholder as new test cases are always generated
      -- just before the test is run, and this way we avoid a more complex
      -- type that for example needs to represent that there's no test case
      -- until after the first getReadyScreen is done which would then
      -- possibly need a Maybe or a difficult tagged type. A placeholder
      -- seems the best option of these right now
      , currentTestCase = ( Algorithm.empty, PLL.Aa, Algorithm.empty )
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.trainerState ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( Transition GetReadyForTest, StartPage ) ->
            ( { model | trainerState = GetReadyScreen }, Cmd.none )

        _ ->
            ( model, Ports.logError "Unexpected PLL Trainer msg + trainer state combination" )


type Transition
    = GetReadyForTest


type TrainerState
    = StartPage
    | GetReadyScreen


type alias Model =
    { trainerState : TrainerState
    , expectedCubeState : Cube
    , currentTestCase : TestCase
    }


type Msg
    = Transition Transition
    | NoOp


type InternalMsg
    = Placeholder


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        state =
            getState shared model

        pageSubtitle =
            Nothing
    in
    StatefulPage.toView pageSubtitle state.view


subscriptions : Shared.Model -> Model -> Sub Msg
subscriptions shared model =
    let
        state =
            getState shared model
    in
    state.subscriptions


getState :
    Shared.Model
    -> Model
    ->
        { view : StatefulPage.StateView Msg
        , subscriptions : Sub Msg
        }
getState shared model =
    case model.trainerState of
        StartPage ->
            PLLTrainer.States.StartPage.state shared { startTest = Transition GetReadyForTest, noOp = NoOp }

        GetReadyScreen ->
            { view = PLLTrainer.States.GetReadyScreen.state shared, subscriptions = Sub.none }
