import {
  applyDefaultIntercepts,
  createFeatureFlagSetter,
} from "support/interceptors";
import { paths } from "support/paths";
import {
  pllTrainerElements,
  pllTrainerStatesNewUser,
} from "./pll-trainer/state-and-elements.helper";

describe("Visual Tests", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
  });
  describe("PLL Trainer", function () {
    it("Looks right", function () {
      cy.visit(paths.pllTrainer);
      cy.clock();
      pllTrainerElements.newUserStartPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Start Page");
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.getReadyScreen.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Get Ready Screen");
      cy.tick(1000);
      pllTrainerElements.testRunning.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Test Running");
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Evaluate Result");
      cy.tick(1000);
      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.correctPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Correct Page");
      pllTrainerElements.correctPage.nextButton.get().click();
      pllTrainerElements.getReadyScreen.container.waitFor();
      cy.tick(1000);
      pllTrainerElements.testRunning.container.waitFor();
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(1000);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Type Of Wrong Page");
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
      pllTrainerElements.wrongPage.container.waitFor();
      cy.percySnapshotWithProperName(
        "PLL Trainer Wrong Page (Correct + Nearly There)"
      );
    });
  });
});

/**
 * INTEGRATE THIS ABOVE WHEN WE DEPLOY THIS TO PRODUCTION AND REMOVE
 * THE FEATURE FLAG
 */
// eslint-disable-next-line mocha/max-top-level-suites
describe("Algorithm Picker Visual Tests", function () {
  it("looks right", function () {
    applyDefaultIntercepts({
      extraHtmlModifiers: [
        createFeatureFlagSetter("displayAlgorithmPicker", true),
      ],
    });

    pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.reloadAndNavigateTo();

    cy.percySnapshotWithProperName("PLL Trainer Pick Algorithm Page: Initial");

    function clearInputTypeAndSubmit(input: string): void {
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(`{selectall}{backspace}${input}{enter}`);
    }

    /**
     * It's important that we add in the waitFors for the errors as otherwise
     * the snapshot can snapshot a wrong error in some instances
     */
    // Add an invalid turnable so we also have an error in the image
    clearInputTypeAndSubmit("U B F2 A ".repeat(20));
    pllTrainerElements.pickAlgorithmPage.invalidTurnableError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Long Algorithm"
    );
    clearInputTypeAndSubmit("");
    pllTrainerElements.pickAlgorithmPage.inputRequiredError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Input Required"
    );
    clearInputTypeAndSubmit("A F R2 B'");
    pllTrainerElements.pickAlgorithmPage.invalidTurnableError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Turnable"
    );
    clearInputTypeAndSubmit("B2 R3 F l f U4");
    pllTrainerElements.pickAlgorithmPage.invalidTurnLengthError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Turn Length"
    );
    clearInputTypeAndSubmit("B2 R U2 U L' y");
    pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Repeated Turnable"
    );
    clearInputTypeAndSubmit("F2 u B Rw L'");
    pllTrainerElements.pickAlgorithmPage.wideMoveStylesMixedError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Wide Move Styles Mixed"
    );
    clearInputTypeAndSubmit("B ( R2 U  ) ' F3 R' L2'");
    pllTrainerElements.pickAlgorithmPage.turnWouldWorkWithoutInterruptionError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Would Work Without Interruption"
    );
    clearInputTypeAndSubmit("M2 R F x U'2 y Rw F2");
    pllTrainerElements.pickAlgorithmPage.apostropheWrongSideOfLengthError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Apostrophe Wrong Side Of Length"
    );
    clearInputTypeAndSubmit("U ( B F' D2");
    pllTrainerElements.pickAlgorithmPage.unclosedParenthesisError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Unclosed Parenthesis"
    );
    clearInputTypeAndSubmit("U B F' ) D2");
    pllTrainerElements.pickAlgorithmPage.unmatchedClosingParenthesisError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Unmatched Closing Parenthesis"
    );
    clearInputTypeAndSubmit("( U (B F') ) D2");
    pllTrainerElements.pickAlgorithmPage.nestedParenthesesError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Nested Parentheses"
    );
    clearInputTypeAndSubmit("( U B F') % D2");
    pllTrainerElements.pickAlgorithmPage.invalidSymbolError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Symbol"
    );
    clearInputTypeAndSubmit("U2 R2 B");
    pllTrainerElements.pickAlgorithmPage.algorithmDoesntMatchCaseError.waitFor();
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Doesn't Solve The Case"
    );
  });
});
