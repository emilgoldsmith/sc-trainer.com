import { addHtmlModifier } from "support/hooks";
import { createFeatureFlagSetter } from "support/interceptors";
import { AUF, PLL } from "support/pll";
import {
  pllTrainerElements,
  pllTrainerStates,
} from "./state-and-elements.helper";

addHtmlModifier(createFeatureFlagSetter("displayAlgorithmPicker", true));

describe("PLL Trainer - Learning Functionality", function () {
  describe("Algorithm Picker", function () {
    it("displays picker exactly once first time that case is encountered", function () {
      pllTrainerStates.testRunning.navigateTo();
      cy.clock();

      const correctBranchCase = [AUF.none, PLL.Aa, AUF.none] as const;
      // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_a
      const correctBranchAlgorithm = "(x) R' U R' D2 R U' R' D2 R2 (x')";
      cy.setCurrentTestCase(correctBranchCase);

      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(300);
      pllTrainerElements.evaluateResult.correctButton.get().click();

      pllTrainerElements.pickAlgorithmPage.assertAllShow();

      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(correctBranchAlgorithm + "{enter}");

      pllTrainerElements.correctPage.container.assertShows();

      pllTrainerElements.correctPage.nextButton.get().click();
      pllTrainerElements.getReadyScreen.container.waitFor();
      cy.tick(1000);
      cy.setCurrentTestCase(correctBranchCase);

      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(300);
      pllTrainerElements.evaluateResult.correctButton.get().click();

      pllTrainerElements.correctPage.container.assertShows();
    });
  });
});
