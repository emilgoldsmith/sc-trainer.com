import {
  applyDefaultIntercepts,
  createFeatureFlagSetter,
} from "support/interceptors";
import { AUF, PLL } from "support/pll";
import {
  pllTrainerElements,
  pllTrainerStatesNewUser,
} from "./state-and-elements.helper";
import allPllsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";

const extraIntercepts: Parameters<typeof applyDefaultIntercepts>[0] = {
  extraHtmlModifiers: [createFeatureFlagSetter("displayAlgorithmPicker", true)],
};

describe("PLL Trainer - Learning Functionality", function () {
  before(function () {
    pllTrainerStatesNewUser.populateAll(extraIntercepts);
  });
  beforeEach(function () {
    applyDefaultIntercepts(extraIntercepts);
  });
  describe("Algorithm Picker", function () {
    it("displays picker exactly once first time that case is encountered", function () {
      pllTrainerStatesNewUser.testRunning.restoreState();
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

    it("doesn't display picker when user already has all algorithms picked", function () {
      cy.setLocalStorage(allPllsPickedLocalStorage);
      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.navigateTo();

      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.correctPage.container.assertShows();

      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.navigateTo();

      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.assertShows();
    });
  });
});
