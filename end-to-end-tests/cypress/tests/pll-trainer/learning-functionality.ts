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
      cy.setCurrentTestCase(correctBranchCase);

      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(300);
      pllTrainerElements.evaluateResult.correctButton.get().click();

      pllTrainerElements.pickAlgorithmPage.assertAllShow();
    });
  });
});
