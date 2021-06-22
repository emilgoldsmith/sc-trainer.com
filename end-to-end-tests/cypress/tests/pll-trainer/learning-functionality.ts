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
import { Key } from "support/keys";

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

            pllTrainerElements.pickAlgorithmPage.container.assertShows();

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

    it.only("focuses input element on load, has all the right elements and then errors as expected", function () {
      // Enter the page dynamically just in case using restoreState could mess up
      // the auto focus
      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.restoreState();
      pllTrainerElements.evaluateResult.correctButton.get().click();

      pllTrainerElements.pickAlgorithmPage.algorithmInput.assertIsFocused();

      cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);
      // The text should somehow communicate that the algorithm we are picking for is the Aa PLL
      pllTrainerElements.pickAlgorithmPage.explanationText
        .get()
        .should("contain.text", "Aa");
      // The page should have an AlgDB link to the case being picked for
      pllTrainerElements.pickAlgorithmPage.algDbLink
        .get()
        .should((link) => {
          expect(link.prop("tagName")).to.equal("A");
          // Assert it opens in new tab
          expect(link.attr("target"), "target").to.equal("_blank");

          expect(link.prop("href"), "href")
            .to.be.a("string")
            .and.contain("algdb.net")
            .and.satisfy(
              (href: string) => href.endsWith("/aa"),
              "ends with /aa"
            );
        })
        .then((link) => {
          // Check that the link actually works
          cy.request(link.attr("href") || "")
            .its("status")
            .should("be.at.least", 200)
            .and("be.lessThan", 300);
        });
      // The page should have any type of expert guidance link, any further assertions
      // would make for too brittle tests
      pllTrainerElements.pickAlgorithmPage.expertPLLGuidanceLink
        .get()
        .should((link) => {
          console.log(link);
          expect(link.prop("tagName")).to.equal("A");
          // Assert it opens in new tab
          expect(link.attr("target"), "target").to.equal("_blank");
        })
        .then((link) => {
          // Check that the link actually works
          cy.request(link.attr("href") || "")
            .its("status")
            .should("be.at.least", 200)
            .and("be.lessThan", 300);
        });

      // And the case specific parts should change if we change the current test case
      cy.setCurrentTestCase([AUF.none, PLL.Ab, AUF.none]);
      pllTrainerElements.pickAlgorithmPage.explanationText
        .get()
        .should("not.contain.text", "Aa");
      pllTrainerElements.pickAlgorithmPage.explanationText
        .get()
        .should("contain.text", "Ab");
      pllTrainerElements.pickAlgorithmPage.algDbLink.get().should((link) => {
        expect(link.prop("tagName")).to.equal("A");
        // Assert it opens in new tab
        expect(link.attr("target"), "target").to.equal("_blank");

        expect(link.prop("href"), "href")
          .to.be.a("string")
          .and.contain("algdb.net")
          .and.satisfy((href: string) => href.endsWith("/ab"), "ends with /ab");
      });

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

/** iphone-8 dimensions from https://docs.cypress.io/api/commands/viewport#Arguments */
const smallViewportConfigOverride: Cypress.TestConfigOverrides = {
  viewportWidth: 375,
  viewportHeight: 667,
};

/** macbook-15 dimensions from https://docs.cypress.io/api/commands/viewport#Arguments */
const largeViewportConfigOverride: Cypress.TestConfigOverrides = {
  viewportWidth: 1440,
  viewportHeight: 900,
};
/**
 * 1. A large touch screen shows shortcuts
 * 2. A large non touch screen shows shortcuts
 * 3. A small non touch screen shows shortcuts
 * 4. A small touch screen doesn't show shortcuts by default
 * 5. A small touch screen after a keyboard event shows shortcuts
 */

// eslint-disable-next-line mocha/max-top-level-suites
describe("Algorithm Picker Dynamic Viewport Tests", function () {
  beforeEach(function () {
    applyDefaultIntercepts(extraIntercepts);
  });
  context("touch screen", function () {
    beforeEach(function () {
      cy.visit(paths.pllTrainer, { onBeforeLoad: simulateIsTouchScreen });
      cy.clock();
    });
    context("large viewport", largeViewportConfigOverride, function () {
      it("displays shortcuts on large viewport with touch screen", function () {
        assertShortcutsDisplay("useMouseAndButtons");
      });
    });
    context("small viewport", smallViewportConfigOverride, function () {
      it("doesnt display shortcuts by default on small viewport with touch screen", function () {
        assertShortcutsDontDisplay("useMouseAndButtons");
      });
      it("displays shortcuts on small viewport with touch screen if a keyboard event was fired", function () {
        cy.pressKey(Key.leftCtrl);
        assertShortcutsDisplay("useMouseAndButtons");
      });
    });
  });
  context("non touch screen", function () {
    /** For a non touch screen we should always show shortcuts as they must have a keyboard */
    beforeEach(function () {
      cy.visit(paths.pllTrainer);
      cy.clock();
    });
    context("large viewport", largeViewportConfigOverride, function () {
      it("displays shortcuts on a large viewport without touch screen", function () {
        assertShortcutsDisplay("useKeyboard");
      });
    });
    context("small viewport", smallViewportConfigOverride, function () {
      it("displays shortcuts on a small viewport with no touch screen", function () {
        assertShortcutsDisplay("useKeyboard");
      });
    });
  });
});

function simulateIsTouchScreen(testWindow: Window) {
  // We need to use defineProperty as it's a read only property, so this
  // is the only way to modify it. We use maxTouchPoints as a proxy for if
  // a touch screen is available due to
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Browser_detection_using_the_user_agent#Mobile_Device_Detection
  // which is the way we are currently doing "feature detection" on touch screen.
  // Of course modify this function if we change the way we detect a touch screen
  // though preferably by adding more things rather than removing the below
  // as that'll keep making it less brittle
  Object.defineProperty(testWindow.navigator, "maxTouchPoints", {
    get() {
      return 1;
    },
  });
}

function assertShortcutsDisplay(method: "useKeyboard" | "useMouseAndButtons") {
  checkWhetherShortcutsDisplay("match", method);
}

function assertShortcutsDontDisplay(
  method: "useKeyboard" | "useMouseAndButtons"
) {
  checkWhetherShortcutsDisplay("not.match", method);
}

function checkWhetherShortcutsDisplay(
  matcher: "match" | "not.match",
  method: "useKeyboard" | "useMouseAndButtons"
) {
  pllTrainerElements.startPage.startButton.get().click();
  pllTrainerElements.getReadyScreen.container.waitFor();
  cy.tick(1000);
  pllTrainerElements.testRunning.container.waitFor();
  cy.mouseClickScreen("center");
  pllTrainerElements.evaluateResult.container.waitFor();
  cy.tick(300);
  pllTrainerElements.evaluateResult.correctButton.get().click();
  pllTrainerElements.pickAlgorithmPage.submitButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Enter"));
  if (method === "useKeyboard") {
    // Note this also checks the enter shortcut actually works as the label implies
    cy.pressKey(Key.enter);
  } else {
    pllTrainerElements.pickAlgorithmPage.submitButton.get().click();
  }
}

function buildShortcutRegex(shortcutText: string): RegExp {
  return new RegExp(String.raw`\(\s*${shortcutText}\s*\)`);
}
