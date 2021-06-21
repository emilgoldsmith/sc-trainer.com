import {
  applyDefaultIntercepts,
  createFeatureFlagSetter,
} from "support/interceptors";
import { allAUFs, AUF, aufToString, PLL } from "support/pll";
import {
  pllTrainerElements,
  pllTrainerStatesNewUser,
} from "./state-and-elements.helper";
import allPllsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";
import { paths } from "support/paths";

// Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_a
const AaAlgorithm = "(x) R' U R' D2 R U' R' D2 R2 (x')";
// Taken from https://www.speedsolving.com/wiki/index.php/PLL#H_Permutation
const HAlgorithm = "M2' U M2' U2 M2' U M2'";

const extraIntercepts: Parameters<typeof applyDefaultIntercepts>[0] = {
  extraHtmlModifiers: [createFeatureFlagSetter("displayAlgorithmPicker", true)],
};

describe("PLL Trainer - Learning Functionality", function () {
  before(function () {
    pllTrainerStatesNewUser.populateAll(extraIntercepts);
  });

  beforeEach(function () {
    applyDefaultIntercepts(extraIntercepts);
    cy.visit(paths.pllTrainer);
    pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.restoreState();
  });

  describe("Algorithm Picker", function () {
    /* eslint-disable mocha/no-setup-in-describe */
    [
      {
        caseName: "Correct Page",
        targetContainer: pllTrainerElements.correctPage.container,
        fromEvaluateToPickAlgorithm: () =>
          pllTrainerElements.evaluateResult.correctButton.get().click(),
        startNextTestButton: pllTrainerElements.correctPage.nextButton,
      },
      {
        caseName: "Wrong --> No Moves Applied",
        targetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
        },
        startNextTestButton: pllTrainerElements.wrongPage.nextButton,
      },
      {
        caseName: "Wrong --> Nearly There",
        targetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
        },
        startNextTestButton: pllTrainerElements.wrongPage.nextButton,
      },
      {
        caseName: "Wrong --> Unrecoverable",
        targetContainer: pllTrainerElements.wrongPage.container,
        fromEvaluateToPickAlgorithm: () => {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
        },
        startNextTestButton: pllTrainerElements.wrongPage.nextButton,
      },
    ].forEach(
      ({
        caseName,
        targetContainer,
        fromEvaluateToPickAlgorithm,
        startNextTestButton,
      }) => {
        /* eslint-enable mocha/no-setup-in-describe */
        describe(caseName, function () {
          it("displays picker exactly once first time that case is encountered and navigates to correct page afterwards", function () {
            pllTrainerStatesNewUser.testRunning.restoreState();
            cy.clock();

            const firstCase = [AUF.none, PLL.Aa, AUF.none] as const;
            const firstCaseCorrectAlgorithm = AaAlgorithm;
            cy.setCurrentTestCase(firstCase);

            cy.mouseClickScreen("center");
            pllTrainerElements.evaluateResult.container.waitFor();
            cy.tick(300);
            fromEvaluateToPickAlgorithm();

            pllTrainerElements.pickAlgorithmPage.assertAllShow();

            pllTrainerElements.pickAlgorithmPage.algorithmInput
              .get()
              .type(firstCaseCorrectAlgorithm + "{enter}");

            targetContainer.assertShows();

            startNextTestButton.get().click();
            pllTrainerElements.getReadyScreen.container.waitFor();
            cy.tick(1000);
            cy.setCurrentTestCase(firstCase);

            cy.mouseClickScreen("center");
            pllTrainerElements.evaluateResult.container.waitFor();
            cy.tick(300);
            fromEvaluateToPickAlgorithm();

            targetContainer.assertShows();
          });
        });
      }
    );

    it("focuses input element on load and then errors as expected", function () {
      // Enter the page dynamically just in case using restoreState could mess up
      // the auto focus
      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.restoreState();
      pllTrainerElements.evaluateResult.correctButton.get().click();

      pllTrainerElements.pickAlgorithmPage.algorithmInput.assertIsFocused();
      cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);

      // Shouldn't have error message on load
      pllTrainerElements.globals.anyErrorMessage.assertDoesntExist();

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
      pllTrainerElements.pickAlgorithmPage.TurnWouldWorkWithoutInterruptionError.assertShows();

      // Errors informatively when parenthesis between turnable and apostrophe encountered
      clearInputTypeAndSubmit("(U)'");
      pllTrainerElements.pickAlgorithmPage.TurnWouldWorkWithoutInterruptionError.assertShows();

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
      clearInputTypeAndSubmit(HAlgorithm);
      pllTrainerElements.pickAlgorithmPage.algorithmDoesntMatchCaseError.assertShows();

      // Submits successfully when correct algorithm passed
      clearInputTypeAndSubmit(AaAlgorithm);
      pllTrainerElements.correctPage.container.assertShows();
    });

    it("accepts algorithms no matter what execution angle or AUF they have", function () {
      allAUFs.forEach((preAUF) =>
        allAUFs.forEach((postAUF) => {
          cy.withOverallNameLogged(
            {
              displayName: "TESTING WITH AUFS",
              message:
                "(" +
                (aufToString[preAUF] || "none") +
                "," +
                (aufToString[postAUF] || "none") +
                ")",
            },
            () => {
              pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.restoreState(
                {
                  log: false,
                }
              );
              cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);
              pllTrainerElements.pickAlgorithmPage.algorithmInput
                .get({ log: false })
                .type(
                  aufToString[preAUF] +
                    AaAlgorithm +
                    aufToString[postAUF] +
                    "{enter}",
                  { log: false, delay: 0 }
                );
              pllTrainerElements.correctPage.container.assertShows();
            }
          );
        })
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
        .type(AaAlgorithm);
      pllTrainerElements.pickAlgorithmPage.submitButton.get().click();

      pllTrainerElements.correctPage.container.assertShows();
    });

    context("LocalStorage", function () {
      it("doesn't display picker when user already has all algorithms picked", function () {
        cy.setLocalStorage(allPllsPickedLocalStorage);
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo();

        pllTrainerElements.evaluateResult.correctButton.get().click();
        pllTrainerElements.correctPage.container.assertShows();

        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo();

        pllTrainerElements.evaluateResult.wrongButton.get().click();
        pllTrainerElements.typeOfWrongPage.container.assertShows();
      });

      it("doesn't display picker if case has picked algorithm on previous visit", function () {
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.restoreState();

        const correctBranchCase = [AUF.none, PLL.Aa, AUF.none] as const;
        // Taken from https://www.speedsolving.com/wiki/index.php/PLL#A_Permutation_:_a
        const correctBranchAlgorithm = "(x) R' U R' D2 R U' R' D2 R2 (x')";
        cy.setCurrentTestCase(correctBranchCase);

        pllTrainerElements.evaluateResult.correctButton.get().click();

        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type(correctBranchAlgorithm + "{enter}");
        pllTrainerElements.correctPage.container.assertShows();

        // Revisit, try again but now we should skip it for same case
        pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo();
        cy.setCurrentTestCase(correctBranchCase);

        pllTrainerElements.evaluateResult.correctButton.get().click();
        pllTrainerElements.correctPage.container.assertShows();
      });
    });
  });
});
