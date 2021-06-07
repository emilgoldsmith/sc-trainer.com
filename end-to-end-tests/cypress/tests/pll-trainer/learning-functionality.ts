import { addHtmlModifier } from "support/hooks";
import { createFeatureFlagSetter } from "support/interceptors";
import { AUF, PLL } from "support/pll";
import { pllTrainerStates } from "./state-and-elements.helper";

addHtmlModifier(createFeatureFlagSetter("displayAlgorithmPicker", true));

describe("PLL Trainer - Learning Functionality", function () {
  describe("Algorithm Picker", function () {
    it.only("test", function () {
      pllTrainerStates.testRunning.navigateTo();
      cy.setCurrentTestCase([AUF.U2, PLL.Ab, AUF.none]);
    });
  });
});
