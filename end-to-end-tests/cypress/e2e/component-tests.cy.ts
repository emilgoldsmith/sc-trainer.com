import { unexposedInternalPaths } from "support/paths";
import { pllTrainerElements } from "./pll-trainer/elements-and-helper-functions";

describe("Component Tests", function () {
  describe("Error Popup", function () {
    it("opens and closes as expected, and sends error exactly when expected", function () {
      const displayErrorTestId = "display-error-button";
      const sentErrorMessageTestId = "sent-error-message";

      cy.visit(unexposedInternalPaths.componentTests.errorPopup);

      pllTrainerElements.globalErrorPopup.container.assertDoesntExist();
      cy.getByTestId(displayErrorTestId).click();

      pllTrainerElements.globalErrorPopup.closeButton.get().click();
      pllTrainerElements.globalErrorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("not.exist");

      cy.getByTestId(displayErrorTestId).click();
      pllTrainerElements.globalErrorPopup.dontSendErrorButton.get().click();
      pllTrainerElements.globalErrorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("not.exist");

      cy.getByTestId(displayErrorTestId).click();
      pllTrainerElements.globalErrorPopup.sendErrorButton.get().click();
      pllTrainerElements.globalErrorPopup.container.assertDoesntExist();
      cy.getByTestId(sentErrorMessageTestId).should("be.visible");
    });
  });
});
