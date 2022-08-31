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
  pllTrainerElements,
  pllTrainerStatesNewUser,
  pllTrainerStatesUserDone,
} from "./state-and-elements";
import { paths } from "support/paths";
import { forceReloadAndNavigateIfDotOnlyIsUsed } from "support/mocha-helpers";

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

  describe("Algorithm Picker", function () {
    beforeEach(function () {
      pllTrainerStatesNewUser.pickAlgorithmPageAfterCorrect.restoreState();
    });

    /* eslint-disable mocha/no-setup-in-describe */
    [
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
  });
});
