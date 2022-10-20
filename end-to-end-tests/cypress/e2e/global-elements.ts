import {
  anyErrorMessage,
  buildElementsCategory,
  buildGlobalsCategory,
  errorMessageElement,
} from "support/elements";

export const globalElements = {
  misc: buildGlobalsCategory({
    anyErrorMessage: anyErrorMessage(),
    feedbackButton: "feedback-button",
  }),
  errorPopup: buildElementsCategory({
    container: errorMessageElement("error-popup-container"),
    closeButton: "close-button",
    sendErrorButton: "send-error-button",
    dontSendErrorButton: "dont-send-error-button",
  }),
};
