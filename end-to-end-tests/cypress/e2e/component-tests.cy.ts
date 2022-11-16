import { unexposedInternalPaths } from "support/paths";
import { globalElements } from "./global-elements";

describe("Component Tests", function () {
  describe("Error Popup", function () {
    it("opens and closes as expected, and sends error exactly when expected", function () {
      const displayErrorTestId = "display-error-button";
      const sentErrorMessageTestId = "sent-error-message";

      cy.visit(unexposedInternalPaths.componentTests.errorPopup);

      globalElements.errorPopup.container.assertDoesntExist();
      cy.getByTestId(displayErrorTestId).click();

      globalElements.errorPopup.closeButton.get().click();
      globalElements.errorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("not.exist");

      cy.getByTestId(displayErrorTestId).click();
      globalElements.errorPopup.dontSendErrorButton.get().click();
      globalElements.errorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("not.exist");

      cy.getByTestId(displayErrorTestId).click();
      globalElements.errorPopup.sendErrorButton.get().click();
      globalElements.errorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("be.visible");
    });
  });

  describe("Inline Error", function () {
    it("displays and sends error exactly when expected", function () {
      const sentErrorMessageTestId = "sent-error-message";
      cy.visit(unexposedInternalPaths.componentTests.inlineError);

      globalElements.inlineError.assertAllShow();

      cy.getByTestId(sentErrorMessageTestId).should("not.exist");

      globalElements.inlineError.sendErrorButton.get().click();

      cy.getByTestId(sentErrorMessageTestId).should("be.visible");
    });
  });

  describe("Notification", function () {
    it("displays and dissappears three different types of notifications", function () {
      const successNotificationTestId = "success-notification";
      const errorNotificationTestId = "error-notification";
      const messageNotificationTestId = "message-notification";
      const startButtonTestId = "start-button";

      cy.visit(unexposedInternalPaths.componentTests.notification);

      cy.getByTestId(startButtonTestId).click();

      [
        errorNotificationTestId,
        successNotificationTestId,
        messageNotificationTestId,
      ].forEach((notificationType) => {
        cy.getByTestId(notificationType).should("not.exist");
        cy.getByTestId(notificationType).should("be.visible");
        cy.getByTestId(notificationType).should("not.exist");
      });
    });
  });
});
