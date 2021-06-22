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
      pllTrainerElements.startPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Start Page");
      pllTrainerElements.startPage.startButton.get().click();
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

    pllTrainerElements.pickAlgorithmPage.algorithmInput
      .get()
      .type("U B F2 ".repeat(20));

    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Long Algorithm"
    );

    function clearInputTypeAndSubmit(input: string): void {
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(`{selectall}{backspace}${input}{enter}`);
    }

    clearInputTypeAndSubmit("");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Input Required"
    );
    clearInputTypeAndSubmit("A F R2 B'");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Turnable"
    );
    clearInputTypeAndSubmit("B2 R3 F l f U4");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Turn Length"
    );
    clearInputTypeAndSubmit("B2 R U2 U L' y");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Repeated Turnable"
    );
    clearInputTypeAndSubmit("F2 u B Rw L'");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Wide Move Styles Mixed"
    );
    clearInputTypeAndSubmit("B R2 U  ) ' F3 R' L2'");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Would Work Without Interruption"
    );
    clearInputTypeAndSubmit("M2 R F x U'2 y Rw F2");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Apostrophe Wrong Side Of Length"
    );
    clearInputTypeAndSubmit("U ( B F' D2");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Unclosed Parenthesis"
    );
    clearInputTypeAndSubmit("U B F' ) D2");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Unmatched Closing Parenthesis"
    );
    clearInputTypeAndSubmit("( U (B F') ) D2");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Nested Parentheses"
    );
    clearInputTypeAndSubmit("( U B F') % D2");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Invalid Symbol"
    );
    clearInputTypeAndSubmit("U2 R2 B");
    cy.percySnapshotWithProperName(
      "PLL Trainer Pick Algorithm Page: Doesn't Solve The Case"
    );
  });
});
