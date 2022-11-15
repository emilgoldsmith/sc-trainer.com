module Pages.UnexposedInternalRoutes.ComponentTests.ErrorPopupTest exposing (Model, Msg, page)

import Css exposing (testid)
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
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
    { popupShowing : Bool
    , sentErrorMessage : Maybe String
    }


init : Model
init =
    { popupShowing = False
    , sentErrorMessage = Nothing
    }


type Msg
    = DisplayPopup
    | DontSendError
    | SendError String


update : Msg -> Model -> Model
update msg model =
    case msg of
        DisplayPopup ->
            { model | popupShowing = True }

        DontSendError ->
            { model | popupShowing = False }

        SendError errorMessage ->
            { model | popupShowing = False, sentErrorMessage = Just errorMessage }


view : Shared.Model -> Model -> View Msg
view shared model =
    { pageSubtitle = Just "Error Popup Component Test"
    , topLevelEventListeners = View.buildTopLevelEventListeners []
    , overlays =
        View.buildOverlays
            (if model.popupShowing then
                [ ErrorMessage.popupOverlay
                    shared.viewportSize
                    shared.palette
                    { errorDescription = "Some error occurred"
                    , sendError = SendError "Some error occurred"
                    , closeWithoutSending = DontSendError
                    }
                ]

             else
                []
            )
    , extraTopLevelAttributes = []
    , body =
        View.fullScreenBody
            (\_ ->
                column []
                    [ Input.button [ testid "display-error-button" ]
                        { onPress = Just DisplayPopup
                        , label =
                            el
                                [ Background.color (rgb255 150 150 150)
                                , padding 10
                                ]
                            <|
                                text "Display Error Popup"
                        }
                    , model.sentErrorMessage
                        |> Maybe.map
                            (\errorMessage ->
                                el [ testid "sent-error-message" ] <| text errorMessage
                            )
                        |> Maybe.withDefault none
                    ]
            )
    }
