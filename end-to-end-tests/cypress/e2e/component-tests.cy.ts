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
});
