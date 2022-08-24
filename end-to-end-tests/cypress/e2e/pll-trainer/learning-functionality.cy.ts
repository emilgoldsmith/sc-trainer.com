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
});
