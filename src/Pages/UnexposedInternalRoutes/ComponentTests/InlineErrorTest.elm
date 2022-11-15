module Pages.UnexposedInternalRoutes.ComponentTests.InlineErrorTest exposing (Model, Msg, page)

import Css exposing (testid)
import Element exposing (..)
import ErrorMessage
import Gen.Params.UnexposedInternalRoutes.ComponentTests.ErrorPopupTest exposing (Params)
import Page
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.sandbox
        { init = init
        , update = update
        , view = view shared
        }


type alias Model =
    { sentErrorMessage : Maybe String
    }


init : Model
init =
    { sentErrorMessage = Nothing
    }


type Msg
    = SendError String


update : Msg -> Model -> Model
update msg model =
    case msg of
        SendError errorMessage ->
            { model | sentErrorMessage = Just errorMessage }


view : Shared.Model -> Model -> View Msg
view shared model =
    { pageSubtitle = Just "Inline Error Component Test"
    , topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays = View.buildOverlays []
    , extraTopLevelAttributes = []
    , body =
        View.fullScreenBody
            (\_ ->
                el [ width fill, height fill ] <|
                    column [ centerX, centerY ]
                        [ paragraph []
                            [ model.sentErrorMessage
                                |> Maybe.map text
                                |> Maybe.map (el [ testid "sent-error-message" ])
                                |> Maybe.withDefault none
                            ]
                        , el
                            [ width (px 200)
                            , height (px 200)
                            ]
                          <|
                            ErrorMessage.viewInline
                                shared.palette
                                { errorDescription = "Some error occurred"
                                , sendError = SendError "test error message"
                                }
                        ]
            )
    }
