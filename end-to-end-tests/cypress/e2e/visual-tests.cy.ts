import {
  addPercyCanvasStyleFixers,
  applyDefaultIntercepts,
} from "support/interceptors";
import { paths } from "support/paths";
import { AUF, PLL } from "support/pll";
import {
  completePLLTestInMilliseconds,
  getReadyWaitTime,
  pllTrainerElements,
} from "./pll-trainer/state-and-elements";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";

describe("Visual Tests", function () {
  beforeEach(function () {
    applyDefaultIntercepts({ extraHtmlModifiers: [addPercyCanvasStyleFixers] });
  });
  describe("PLL Trainer", function () {
    it("looks right", function () {
      cy.visit(paths.pllTrainer);
      cy.percySnapshotWithProperName(
        "PLL Trainer Pick Target Parameters Page",
        { ensureFullHeightIsCaptured: true }
      );
      pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
      pllTrainerElements.newUserStartPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Start Page New User", {
        ensureFullHeightIsCaptured: true,
      });
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.newCasePage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer New Case Page");
      // Use a "done" user from here
      cy.setLocalStorage(fullyPopulatedLocalStorage);
      cy.visit(paths.pllTrainer);
      cy.clock();
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.getReadyState.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Get Ready Screen");
      cy.tick(getReadyWaitTime);
      pllTrainerElements.testRunning.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Test Running");
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Evaluate Result");
      cy.tick(getReadyWaitTime);
      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.correctPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Correct Page For Old Case");
      pllTrainerElements.correctPage.nextButton.get().click();
      pllTrainerElements.getReadyState.container.waitFor();
      cy.tick(getReadyWaitTime);
      pllTrainerElements.testRunning.container.waitFor();
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(getReadyWaitTime);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      cy.percySnapshotWithProperName("PLL Trainer Type Of Wrong Page");
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
      pllTrainerElements.wrongPage.container.waitFor();
      cy.percySnapshotWithProperName(
        "PLL Trainer Wrong Page (Correct + Nearly There)"
      );
      cy.clock().then((clock) => clock.restore());

      // All the new pick algorithm type visual tests
      cy.clearLocalStorage();
      completePLLTestInMilliseconds(500, {
        correct: true,
        startingState: "doNewVisit",
        endingState: "pickAlgorithmPage",
      });

      cy.percySnapshotWithProperName(
        "PLL Trainer Pick Algorithm Page: Initial"
      );

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

      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.none, PLL.Ga, AUF.none],
        correct: true,
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.none, PLL.H, AUF.none],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(2340, {
        forceTestCase: [AUF.none, PLL.Aa, AUF.none],
        correct: true,
        startingState: "doNewVisit",
      });
      cy.visit(paths.pllTrainer);
      cy.percySnapshotWithProperName("PLL Trainer Recurring User Start Page", {
        ensureFullHeightIsCaptured: true,
      });

      // Just an assurance that our AUFs and cases are displaying correctly.
      cy.clearLocalStorage();
      completePLLTestInMilliseconds(1000, {
        // This is the AUF that matches the other AUF so that there won't be a driller
        // but actually the wrong page callback
        forceTestCase: [AUF.UPrime, PLL.Ua, AUF.none],
        overrideDefaultAlgorithm: "M2 U M' U2 M U M2",
        correct: true,
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.U, PLL.Ua, AUF.U2],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
        wrongPageCallback: () =>
          cy.percySnapshotWithProperName("U [Ua] U2 standard slice algorithm"),
      });

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(1000, {
        // This is the AUF that matches the other AUF so that there won't be a driller
        // but actually the wrong page callback
        forceTestCase: [AUF.U2, PLL.Ua, AUF.U],
        // Use an algorithm that has a different preAUF but same postAUF
        overrideDefaultAlgorithm: "R2 U' S' U2' S U' R2",
        correct: true,
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(1000, {
        // This same case corresponds to [Ua] U' with the standard slice algorithm
        forceTestCase: [AUF.U, PLL.Ua, AUF.U2],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
        wrongPageCallback: () =>
          cy.percySnapshotWithProperName(
            "[Ua] U' standard slice algorithm equivalent"
          ),
      });

      // Now let's test some postAUFs with the Gc algorithm
      cy.clearLocalStorage();
      completePLLTestInMilliseconds(1000, {
        // This is the AUF that matches the other AUF so that there won't be a driller
        // but actually the wrong page callback
        forceTestCase: [AUF.UPrime, PLL.Gc, AUF.U],
        overrideDefaultAlgorithm: "(y) R2 U' R U' R U R' U R2 D' U R U' R' D",
        correct: true,
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(1000, {
        forceTestCase: [AUF.UPrime, PLL.Gc, AUF.none],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
        wrongPageCallback: () =>
          cy.percySnapshotWithProperName("U' [Gc] with Emil's main algorithm"),
      });

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(1000, {
        // This is the AUF that matches the other AUF so that there won't be a driller
        // but actually the wrong page callback
        forceTestCase: [AUF.UPrime, PLL.Gc, AUF.none],
        // Use an algorithm that has same preAUF but different postAUF
        overrideDefaultAlgorithm: "(y) R2' u' (R U' R U R') u R2 (y) R U' R'",
        correct: true,
        startingState: "doNewVisit",
      });
      completePLLTestInMilliseconds(1000, {
        // This same case corresponds to U' [Gc] U' with the previous algorithm
        forceTestCase: [AUF.UPrime, PLL.Gc, AUF.none],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
        wrongPageCallback: () =>
          cy.percySnapshotWithProperName(
            "U' [Gc] U' equivalent with Emil's main algorithm"
          ),
      });

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(500, {
        forceTestCase: [AUF.none, PLL.Gc, AUF.none],
        correct: true,
        startingState: "doNewVisit",
        correctPageCallback: () =>
          cy.percySnapshotWithProperName("Correct Page For New Case"),
      });

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(500, {
        forceTestCase: [AUF.none, PLL.Gc, AUF.none],
        correct: false,
        wrongType: "unrecoverable",
        startingState: "doNewVisit",
        algorithmDrillerExplanationPageCallback: () => {
          pllTrainerElements.algorithmDrillerExplanationPage.container.waitFor();
          cy.percySnapshotWithProperName(
            "Algorithm Driller Explanation Page (Wrong Case)"
          );
        },
      });

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(10000, {
        forceTestCase: [AUF.none, PLL.Gc, AUF.none],
        correct: true,
        startingState: "doNewVisit",
        algorithmDrillerExplanationPageCallback: () => {
          pllTrainerElements.algorithmDrillerExplanationPage.container.waitFor();
          cy.percySnapshotWithProperName(
            "Algorithm Driller Explanation Page (Correct Case)"
          );
        },
        algorithmDrillerStatusPageCallback: () =>
          cy.percySnapshotWithProperName("Algorithm Driller Status Page"),
      });
      for (let i = 0; i < 3; i++) {
        completePLLTestInMilliseconds(500, {
          correct: true,
          startingState: "algorithmDrillerStatusPage",
          endingState: i < 2 ? "algorithmDrillerStatusPage" : undefined,
        });
      }

      pllTrainerElements.algorithmDrillerSuccessPage.container.waitFor();
      cy.percySnapshotWithProperName("Algorithm Driller Success Page");
    });
  });
});
