import {
  anyErrorMessage,
  buildElementsCategory,
  buildGlobalsCategory,
  errorMessageElement,
  optionalElement,
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
  inlineError: buildElementsCategory({
    container: errorMessageElement("inline-error-container"),
    sendErrorButton: "send-error-button",
  }),
  notification: buildGlobalsCategory({
    container: "notification-container",
    errorNotification: "error-notification",
    successNotification: "success-notification",
    messageNotification: "message-notification",
  }),
};
