import { applyDefaultIntercepts } from "support/interceptors";
import {
  allAUFs,
  AUF,
  aufToAlgorithmString,
  PLL,
  pllToAlgorithmString,
} from "support/pll";
import {
  completePLLTestInMilliseconds,
  evaluateResultIgnoreTransitionsWaitTime,
  fromGetReadyForTestThroughEvaluateResult,
  pllTrainerElements,
  pllTrainerStatesNewUser,
  pllTrainerStatesUserDone,
} from "./state-and-elements";
import allPllsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";
import { paths } from "support/paths";
import { Key } from "support/keys";
import { forceReloadAndNavigateIfDotOnlyIsUsed } from "support/mocha-helpers";
import {
  assertCubeIsDifferentFromAlias,
  assertCubeMatchesAlias,
} from "support/assertions";

forceReloadAndNavigateIfDotOnlyIsUsed();

describe("PLL Trainer - Learning Functionality", function () {
  before(function () {
    pllTrainerStatesUserDone.populateAll();
    pllTrainerStatesNewUser.populateAll();
  });

  beforeEach(function () {
    applyDefaultIntercepts();
    cy.visit(paths.pllTrainer);
  });

  describe("Pick Target Parameters Page", function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    const elems = pllTrainerElements.pickTargetParametersPage;

    // eslint-disable-next-line mocha/no-setup-in-describe
    [
      {
        method: "enter in recognition time input",
        submit: () => elems.recognitionTimeInput.get().type("{enter}"),
      },
      {
        method: "enter in tps input",
        submit: () => elems.targetTPSInput.get().type("{enter}"),
      },
    ].forEach(({ method, submit }) =>
      it("submits exactly when there are no errors, using " + method)
    );

    it("persists the target parameters", function () {
      const recognitionTime = "3.5";
      const tps = "1.3";

      elems.recognitionTimeInput
        .get()
        .type("{selectall}{backspace}" + recognitionTime);
      elems.targetTPSInput.get().type("{selectall}{backspace}" + tps);
      elems.submitButton.get().click();

      pllTrainerElements.newUserStartPage.editTargetParametersButton
        .get()
        .click();

      // This asserts that it preserves it through a session
      elems.recognitionTimeInput.get().should("have.value", recognitionTime);
      elems.targetTPSInput.get().should("have.value", tps);

      // Also test that it persists through separate sessions
      pllTrainerStatesUserDone.pickTargetParametersPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
      });
      elems.recognitionTimeInput.get().should("have.value", recognitionTime);
      elems.targetTPSInput.get().should("have.value", tps);
    });
  });

  describe("New User Start Page", function () {
    beforeEach(function () {
      pllTrainerStatesNewUser.startPage.restoreState();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      pllTrainerElements.newCasePage.container.assertShows();
    });
  });

  describe("New Case Page", function () {
    beforeEach(function () {
      pllTrainerStatesNewUser.newCasePage.restoreState();
    });

    it("goes from start page to new case page for new user", function () {
      pllTrainerStatesNewUser.startPage.restoreState();
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.newCasePage.container.assertShows();
    });

    it("goes from start page to get ready state for done user", function () {
      pllTrainerStatesUserDone.startPage.restoreState();
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.getReadyState.container.assertShows();
    });

    it("displays new case page exactly when a new pll, pre- or postAUF is next", function () {
      // Make sure local storage is correct
      pllTrainerStatesNewUser.startPage.restoreState();

      cy.log("This is a completely new user so new case page should display");
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.UPrime, AUF.UPrime],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertShows();
        },
      });

      cy.log("This is a new preAUF so should display new case page");
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertShows();
        },
      });

      cy.log(
        "This is the same case as last time so no new case page should display"
      );
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertDoesntExist();
        },
      });

      cy.log(
        "This is a new postAUF even with known preAUF so should still display new case page"
      );
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.U, AUF.U2],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertShows();
        },
      });

      cy.log(
        "This is a case that hasn't been seen before, but each type of pre- and post-AUF have been tested independently so it shouldn't count as a new case"
      );
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.UPrime, AUF.U2],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertDoesntExist();
        },
      });

      cy.log(
        "This is the first time there is no postAUF, and while this is a \"new\" case we don't want to count it as it's simply the act of not making a move. Also note that the preAUF is of course seen before otherwise it would be a new case"
      );
      completePLLTestInMilliseconds(500, PLL.Aa, {
        aufs: [AUF.UPrime, AUF.none],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertDoesntExist();
        },
      });

      cy.log("New PLL so should display");
      completePLLTestInMilliseconds(500, PLL.H, {
        aufs: [AUF.U, AUF.none],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertShows();
        },
      });

      cy.log(
        "H perm is fully symmetrical so preAUF and postAUF are equivalent in that sense and this shouldn't be a new case"
      );
      completePLLTestInMilliseconds(500, PLL.H, {
        aufs: [AUF.none, AUF.U],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertDoesntExist();
        },
      });

      cy.log(
        "This is a different combination though so should display the new case page"
      );
      completePLLTestInMilliseconds(500, PLL.H, {
        aufs: [AUF.U2, AUF.none],
        correct: true,
        newCasePageCallback() {
          pllTrainerElements.newCasePage.container.assertShows();
        },
      });
    });
  });

  describe("Correct Page", function () {
    it("displays good job text on a new case", function () {
      pllTrainerStatesNewUser.correctPage.restoreState();
      pllTrainerElements.correctPage.goodJobText.assertShows();
    });

    it("doesn't display good job text on a known case", function () {
      pllTrainerStatesUserDone.correctPage.restoreState();
      pllTrainerElements.correctPage.container.waitFor();
      pllTrainerElements.correctPage.goodJobText.assertDoesntExist();
    });
  });

  describe("Algorithm Picker", function () {
    beforeEach(function () {
      pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.restoreState();
    });

    /* eslint-disable mocha/no-setup-in-describe */
    [
      {
        caseName: "Correct Page",
        pickAlgorithmElementThatShouldShow:
          pllTrainerElements.pickAlgorithmPage.correctText,
        firstTargetContainer: pllTrainerElements.correctPage.container,
        secondTargetContainer: pllTrainerElements.correctPage.container,
        fromEvaluateToPickAlgorithm: () =>
          pllTrainerElements.evaluateResult.correctButton.get().click(),
      },
      {
        caseName: "Wrong --> No Moves Applied",
        pickAlgorithmElementThatShouldShow:
          pllTrainerElements.pickAlgorithmPage.wrongText,
        firstTargetContainer:
          pllTrainerElements.algorithmDrillerExplanationPage.container,
        secondTargetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
        },
      },
      {
        caseName: "Wrong --> Nearly There",
        pickAlgorithmElementThatShouldShow:
          pllTrainerElements.pickAlgorithmPage.wrongText,
        firstTargetContainer:
          pllTrainerElements.algorithmDrillerExplanationPage.container,
        secondTargetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
        },
      },
      {
        caseName: "Wrong --> Unrecoverable",
        pickAlgorithmElementThatShouldShow:
          pllTrainerElements.pickAlgorithmPage.wrongText,
        firstTargetContainer:
          pllTrainerElements.algorithmDrillerExplanationPage.container,
        secondTargetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
        },
      },
    ].forEach(
      ({
        caseName,
        pickAlgorithmElementThatShouldShow,
        firstTargetContainer,
        secondTargetContainer,
        fromEvaluateToPickAlgorithm,
      }) => {
        /* eslint-enable mocha/no-setup-in-describe */
        describe(caseName, function () {
          it("displays picker exactly once first time that case is encountered and navigates to the expected page afterwards", function () {
            pllTrainerStatesNewUser.testRunning.restoreState();
            cy.clock();

            const testCase = [AUF.none, PLL.Aa, AUF.none] as const;
            const testCaseCorrectAlgorithm = pllToAlgorithmString[PLL.Aa];
            cy.setCurrentTestCase(testCase);

            cy.mouseClickScreen("center");
            pllTrainerElements.evaluateResult.container.waitFor();
            cy.tick(evaluateResultIgnoreTransitionsWaitTime);
            cy.clock().then((clock) => clock.restore());
            fromEvaluateToPickAlgorithm();

            pllTrainerElements.pickAlgorithmPage.container.assertShows();
            pickAlgorithmElementThatShouldShow.assertShows();

            pllTrainerElements.pickAlgorithmPage.algorithmInput
              .get()
              .type(testCaseCorrectAlgorithm + "{enter}");

            firstTargetContainer.assertShows();

            pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo(
              {
                retainCurrentLocalStorage: true,
                navigateOptions: {
                  case: testCase,
                  algorithm: testCaseCorrectAlgorithm,
                  targetParametersPicked: true,
                  isNewCase: false,
                },
              }
            );
            fromEvaluateToPickAlgorithm();

            secondTargetContainer.assertShows();
          });
        });
      }
    );

    it("focuses input element on load, has all the right elements and then errors as expected", function () {
      // Should require input if pressing enter right away
      pllTrainerElements.pickAlgorithmPage.algorithmInput.get().type("{enter}");
      pllTrainerElements.pickAlgorithmPage.inputRequiredError.assertShows();

      // Should no longer require input after input
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("asdfgfda{enter}");
      pllTrainerElements.pickAlgorithmPage.inputRequiredError.assertDoesntExist();

      // Should require input again after deleting the input
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("{selectall}{backspace}{enter}");
      pllTrainerElements.pickAlgorithmPage.inputRequiredError.assertShows();

      function clearInputTypeAndSubmit(input: string): void {
        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type(`{selectall}{backspace}${input}{enter}`);
      }
      // Errors informatively when invalid turnable encountered
      clearInputTypeAndSubmit("U B A");
      pllTrainerElements.pickAlgorithmPage.invalidTurnableError.assertShows();

      // Errors informatively when invalid turn length encountered
      clearInputTypeAndSubmit("U4");
      pllTrainerElements.pickAlgorithmPage.invalidTurnLengthError.assertShows();

      // Errors informatively when repeated turnable encountered
      clearInputTypeAndSubmit("U2U");
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertShows();

      // Errors informatively when mixed wide move styles encountered
      clearInputTypeAndSubmit("u B Rw");
      pllTrainerElements.pickAlgorithmPage.wideMoveStylesMixedError.assertShows();

      // Errors informatively when space between turnable and apostrophe encountered
      clearInputTypeAndSubmit("U '");
      pllTrainerElements.pickAlgorithmPage.turnWouldWorkWithoutInterruptionError.assertShows();

      // Errors informatively when parenthesis between turnable and apostrophe encountered
      clearInputTypeAndSubmit("(U)'");
      pllTrainerElements.pickAlgorithmPage.turnWouldWorkWithoutInterruptionError.assertShows();

      // Errors informatively when apostrophe on wrong side of length encountered
      clearInputTypeAndSubmit("U'2");
      pllTrainerElements.pickAlgorithmPage.apostropheWrongSideOfLengthError.assertShows();

      // Errors informatively when unclosed parenthesis encountered
      clearInputTypeAndSubmit("U ( B F' D2");
      pllTrainerElements.pickAlgorithmPage.unclosedParenthesisError.assertShows();

      // Errors informatively when unmatched closing parenthesis encountered
      clearInputTypeAndSubmit("U B F' ) D2");
      pllTrainerElements.pickAlgorithmPage.unmatchedClosingParenthesisError.assertShows();

      // Errors informatively when nested parentheses encountered
      clearInputTypeAndSubmit("( U (B F') ) D2");
      pllTrainerElements.pickAlgorithmPage.nestedParenthesesError.assertShows();

      // Errors informatively when invalid symbol encountered
      clearInputTypeAndSubmit("( U B F') % D2");
      pllTrainerElements.pickAlgorithmPage.invalidSymbolError.assertShows();

      // Errors informatively an algorithm that doesn't match the case is encountered
      cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);
      clearInputTypeAndSubmit(pllToAlgorithmString[PLL.H]);
      pllTrainerElements.pickAlgorithmPage.algorithmDoesntMatchCaseError.assertShows();

      // Submits successfully when correct algorithm passed
      clearInputTypeAndSubmit(pllToAlgorithmString[PLL.Aa]);
      pllTrainerElements.correctPage.container.assertShows();
    });

    it("accepts algorithms no matter what execution angle or AUF they have, and which cube rotation they end on", function () {
      allAUFs.forEach((preAUF) =>
        allAUFs.forEach((postAUF) =>
          ["", "y", "x", "z"].forEach((rotation) => {
            cy.withOverallNameLogged(
              {
                displayName: "TESTING WITH AUFS/ROTATION",
                message:
                  "(" +
                  (aufToAlgorithmString[preAUF] || "none") +
                  "," +
                  (aufToAlgorithmString[postAUF] || "none") +
                  "," +
                  (rotation || "no rotation") +
                  ")",
              },
              () => {
                pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.restoreState(
                  {
                    log: false,
                  }
                );
                cy.setCurrentTestCase([AUF.none, PLL.H, AUF.none]);
                pllTrainerElements.pickAlgorithmPage.algorithmInput
                  .get({ log: false })
                  .type(
                    aufToAlgorithmString[preAUF] +
                      pllToAlgorithmString[PLL.H] +
                      aufToAlgorithmString[postAUF] +
                      rotation +
                      "{enter}",
                    { log: false, delay: 0 }
                  );
                pllTrainerElements.correctPage.container.assertShows();
              }
            );
          })
        )
      );
    });

    it("only updates error message on submit", function () {
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertDoesntExist();
      pllTrainerElements.pickAlgorithmPage.algorithmInput.get().type("U U");
      // Check error didn't show yet
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertDoesntExist();

      pllTrainerElements.pickAlgorithmPage.algorithmInput.get().type("{enter}");
      // Now it should show because we submitted
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertShows();

      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("{selectall}{backspace}U4");
      // It shouldn't show yet
      pllTrainerElements.pickAlgorithmPage.invalidTurnLengthError.assertDoesntExist();
      pllTrainerElements.pickAlgorithmPage.algorithmInput.get().type("{enter}");
      // Now it should show because we submitted
      pllTrainerElements.pickAlgorithmPage.invalidTurnLengthError.assertShows();

      // Now try with the button
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertDoesntExist();
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("{selectall}{backspace}U U");
      // Check error didn't show yet
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertDoesntExist();

      pllTrainerElements.pickAlgorithmPage.submitButton.get().click();
      // Now it should show because we submitted
      pllTrainerElements.pickAlgorithmPage.repeatedTurnableError.assertShows();
    });

    it("continues to next page on submit button click", function () {
      cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(pllToAlgorithmString[PLL.Aa]);
      pllTrainerElements.pickAlgorithmPage.submitButton.get().click();

      pllTrainerElements.correctPage.container.assertShows();
    });

    context("Persistence", function () {
      it("doesn't display picker when user already has all algorithms picked in local storage", function () {
        cy.setLocalStorage(allPllsPickedLocalStorage);
        // Note we use reload here as we don't want restore to save an old state of the
        // model that doesn't include the plls picked
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo(
          {
            retainCurrentLocalStorage: true,
            navigateOptions: {
              case: [AUF.none, PLL.H, AUF.none],
              algorithm: pllToAlgorithmString[PLL.H],
            },
          }
        );

        pllTrainerElements.evaluateResult.correctButton.get().click();
        pllTrainerElements.correctPage.container.assertShows();

        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo(
          {
            retainCurrentLocalStorage: true,
            navigateOptions: {
              targetParametersPicked: true,
              // Just ensure it is not the same as above so that new case shows
              case: [AUF.none, PLL.Ga, AUF.none],
              isNewCase: true,
            },
          }
        );

        pllTrainerElements.evaluateResult.wrongButton.get().click();
        pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
        pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows();
      });

      it("doesn't display picker if case has picked algorithm on previous visit", function () {
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.restoreState();

        const correctBranchCase = [AUF.none, PLL.Aa, AUF.none] as const;
        const correctBranchAlgorithm = pllToAlgorithmString[PLL.Aa];
        cy.setCurrentTestCase(correctBranchCase);

        pllTrainerElements.evaluateResult.correctButton.get().click();

        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type(correctBranchAlgorithm + "{enter}");
        pllTrainerElements.correctPage.container.assertShows();

        // Revisit, try again but now we should skip it for same case
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo(
          {
            retainCurrentLocalStorage: true,
            navigateOptions: {
              targetParametersPicked: true,
              case: correctBranchCase,
              isNewCase: false,
            },
          }
        );

        pllTrainerElements.evaluateResult.correctButton.get().click();
        pllTrainerElements.correctPage.container.assertShows();

        // ---------------------------------------------------
        // Now we try it with a wrong route
        // ---------------------------------------------------
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.restoreState();

        const wrongBranchCase = [AUF.none, PLL.H, AUF.none] as const;
        const wrongBranchAlgorithm = pllToAlgorithmString[PLL.H];
        cy.setCurrentTestCase(wrongBranchCase);

        pllTrainerElements.evaluateResult.wrongButton.get().click();
        pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();

        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type(wrongBranchAlgorithm + "{enter}");
        pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows();

        // Revisit, try again but now we should skip it for same case
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo(
          {
            retainCurrentLocalStorage: true,
            navigateOptions: {
              targetParametersPicked: true,
              case: wrongBranchCase,
              isNewCase: false,
            },
          }
        );

        pllTrainerElements.evaluateResult.wrongButton.get().click();
        pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();

        pllTrainerElements.wrongPage.container.assertShows();
      });
    });
  });

  describe("Algorithm Driller Explanation Page", function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    const elements = pllTrainerElements.algorithmDrillerExplanationPage;

    it("goes to driller when a new case is not solved correctly and displays exactly wrong text", function () {
      // Driller first time pll is encountered
      completePLLTestInMilliseconds(500, PLL.Aa, {
        correct: false,
        aufs: [AUF.none, AUF.none],
        algorithmDrillerExplanationPageCallback: () => {
          elements.wrongText.assertConsumableViaVerticalScroll(
            elements.container.specifier
          );
          elements.correctText.assertDoesntExist();
        },
      });
      // Driller when new pre-AUF for the pll is encountered despite pll itself being seen before
      completePLLTestInMilliseconds(500, PLL.Aa, {
        correct: false,
        aufs: [AUF.U, AUF.none],
        algorithmDrillerExplanationPageCallback: () => {
          elements.wrongText.assertConsumableViaVerticalScroll(
            elements.container.specifier
          );
          elements.correctText.assertDoesntExist();
        },
      });
      // Driller when new post-AUF for the pll is encountered despite pll itself being seen before
      completePLLTestInMilliseconds(500, PLL.Aa, {
        correct: false,
        aufs: [AUF.none, AUF.UPrime],
        algorithmDrillerExplanationPageCallback: () => {
          elements.wrongText.assertConsumableViaVerticalScroll(
            elements.container.specifier
          );
          elements.correctText.assertDoesntExist();
        },
      });
      // No driller when both pre-AUF and post-AUF are seen before even if not in this combination
      completePLLTestInMilliseconds(500, PLL.Aa, {
        correct: false,
        aufs: [AUF.U, AUF.UPrime],
        algorithmDrillerExplanationPageCallback: () =>
          elements.container.assertDoesntExist(),
      });
    });

    it("doesn't go to driller if new case solved quickly and correctly", function () {
      // No driller first time pll is encountered
      completePLLTestInMilliseconds(100, PLL.Ga, {
        correct: true,
        aufs: [AUF.U2, AUF.U2],
        algorithmDrillerExplanationPageCallback: () =>
          pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
      });
      // No driller when new pre-AUF for the pll is encountered despite pll itself being seen before
      completePLLTestInMilliseconds(100, PLL.Ga, {
        correct: true,
        aufs: [AUF.UPrime, AUF.U2],
        algorithmDrillerExplanationPageCallback: () =>
          pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
      });
      // No driller when new post-AUF for the pll is encountered despite pll itself being seen before
      completePLLTestInMilliseconds(100, PLL.Ga, {
        correct: true,
        aufs: [AUF.U2, AUF.none],
        algorithmDrillerExplanationPageCallback: () =>
          pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
      });
      // No driller when both pre-AUF and post-AUF are seen before even if not in this combination
      completePLLTestInMilliseconds(100, PLL.Ga, {
        correct: true,
        aufs: [AUF.UPrime, AUF.none],
        algorithmDrillerExplanationPageCallback: () =>
          pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
      });
    });

    it("goes to driller when a new case is solved correctly but slowly and displays exactly correct text", function () {
      cy.withOverallNameLogged(
        { message: "Driller first time pll is encountered" },
        () => {
          completePLLTestInMilliseconds(10000, PLL.Gb, {
            correct: true,
            aufs: [AUF.UPrime, AUF.UPrime],
            algorithmDrillerExplanationPageCallback: () => {
              elements.correctText.assertConsumableViaVerticalScroll(
                elements.container.specifier
              );
              elements.wrongText.assertDoesntExist();
            },
          });
        }
      );
      cy.withOverallNameLogged(
        {
          message:
            "Driller when new pre-AUF for the pll is encountered despite pll itself being seen before",
        },
        () => {
          completePLLTestInMilliseconds(10000, PLL.Gb, {
            correct: true,
            aufs: [AUF.none, AUF.UPrime],
            algorithmDrillerExplanationPageCallback: () => {
              elements.correctText.assertConsumableViaVerticalScroll(
                elements.container.specifier
              );
              elements.wrongText.assertDoesntExist();
            },
          });
        }
      );
      cy.withOverallNameLogged(
        {
          message:
            "Driller when new post-AUF for the pll is encountered despite pll itself being seen before",
        },
        () => {
          completePLLTestInMilliseconds(10000, PLL.Gb, {
            correct: true,
            aufs: [AUF.UPrime, AUF.U2],
            algorithmDrillerExplanationPageCallback: () => {
              elements.correctText.assertConsumableViaVerticalScroll(
                elements.container.specifier
              );
              elements.wrongText.assertDoesntExist();
            },
          });
        }
      );
      cy.withOverallNameLogged(
        {
          message:
            "No driller when both pre-AUF and post-AUF are seen before even if not in this combination",
        },
        () => {
          completePLLTestInMilliseconds(10000, PLL.Gb, {
            correct: true,
            aufs: [AUF.none, AUF.U2],
            algorithmDrillerExplanationPageCallback: () =>
              elements.container.assertDoesntExist(),
          });
        }
      );
    });

    it("goes to driller correctly for edge cases", function () {
      cy.withOverallNameLogged(
        { message: "First time it's encountered we definitely drill" },
        () => {
          completePLLTestInMilliseconds(10000, PLL.H, {
            correct: false,
            aufs: [AUF.UPrime, AUF.UPrime],
            algorithmDrillerExplanationPageCallback: () =>
              pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows(),
          });
        }
      );

      cy.withOverallNameLogged(
        {
          message:
            "We don't drill on an equivalent (due to symmetry of the case) set of AUFs",
        },
        () => {
          completePLLTestInMilliseconds(10000, PLL.H, {
            correct: false,
            aufs: [AUF.none, AUF.U2],
            algorithmDrillerExplanationPageCallback: () =>
              pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
          });
        }
      );

      cy.withOverallNameLogged(
        {
          message:
            "We don't drill if it's a known preAUF and an unknown \"none\" post-AUF this is because that just means not to make a move in the end which shouldn't be considered new",
        },
        () => {
          completePLLTestInMilliseconds(10000, PLL.Ga, {
            correct: false,
            aufs: [AUF.U, AUF.U],
            algorithmDrillerExplanationPageCallback: () =>
              pllTrainerElements.algorithmDrillerExplanationPage.container.assertShows(),
          });
          completePLLTestInMilliseconds(10000, PLL.Ga, {
            correct: false,
            aufs: [AUF.U, AUF.none],
            algorithmDrillerExplanationPageCallback: () =>
              pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist(),
          });
        }
      );
    });
  });

  describe("Algorithm Driller Success Page", function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    const elements = pllTrainerElements.algorithmDrillerSuccessPage;

    beforeEach(function () {
      pllTrainerStatesNewUser.algorithmDrillerSuccessPage.restoreState();
    });

    it("looks right", function () {
      elements.assertAllShow();
    });

    it("sizes elements correctly", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("starts new test on button click", function () {
      elements.nextTestButton.get().click();
      // Since it's a new user and this was the first case they learned,
      // the learning algorithm should always present a new case afterwards
      pllTrainerElements.newCasePage.container.assertShows();
    });

    it("starts new test on space bar press", function () {
      cy.pressKey(Key.space);
      // Since it's a new user and this was the first case they learned,
      // the learning algorithm should always present a new case afterwards
      pllTrainerElements.newCasePage.container.assertShows();
    });
  });
});
