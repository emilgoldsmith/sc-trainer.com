import { getKeyValue, Key } from "support/keys";
import { installClock, setTimeTo, tick } from "support/clock";
import {
  pllTrainerStatesUserDone,
  pllTrainerElements,
  pllTrainerStatesNewUser,
  completePLLTestInMilliseconds,
  getReadyWaitTime,
} from "./state-and-elements";
import { paths } from "support/paths";
import { applyDefaultIntercepts } from "support/interceptors";
import {
  AUF,
  aufToAlgorithmString,
  PLL,
  pllToAlgorithmString,
  pllToPllLetters,
} from "support/pll";
import allPllsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";
import { forceReloadAndNavigateIfDotOnlyIsUsed } from "support/mocha-helpers";
import {
  assertCubeMatchesAlias,
  assertNonFalsyStringsDifferent,
  assertNonFalsyStringsEqual,
} from "support/assertions";

forceReloadAndNavigateIfDotOnlyIsUsed();

describe("PLL Trainer - Basic Functionality", function () {
  before(function () {
    pllTrainerStatesUserDone.populateAll();
    pllTrainerStatesNewUser.populateAll();
  });

  beforeEach(function () {
    applyDefaultIntercepts();
    cy.visit(paths.pllTrainer);
  });

  describe("Start Page", function () {
    context("for a new user", function () {
      beforeEach(function () {
        pllTrainerStatesNewUser.startPage.restoreState();
      });

      it("has all the correct elements", function () {
        // These elements should all display without scrolling
        pllTrainerElements.newUserStartPage.welcomeText.assertShows();
        pllTrainerElements.newUserStartPage.welcomeText.assertContainedByWindow();
        // These ones we accept possibly having to scroll for so just check it exists
        // We check it's visibility including scroll in the element sizing
        pllTrainerElements.newUserStartPage.cubeStartExplanation
          .get()
          .should("exist");
        pllTrainerElements.newUserStartPage.cubeStartState
          .get()
          .should("exist");
        pllTrainerElements.newUserStartPage.startButton.get().should("exist");
        pllTrainerElements.newUserStartPage.instructionsText
          .get()
          .should("exist");
        pllTrainerElements.newUserStartPage.learningResources
          .get()
          .should("exist");
        pllTrainerElements.newUserStartPage.editTargetParametersButton
          .get()
          .should("exist");

        // A smoke test that we have added some links for the cubing terms
        pllTrainerElements.newUserStartPage.container.get().within(() => {
          cy.get("a").should("have.length.above", 0);
        });
      });

      it("sizes elements reasonably", function () {
        cy.assertNoHorizontalScrollbar();
        const containerId =
          pllTrainerElements.newUserStartPage.container.specifier;
        // This one is allowed vertical scrolling, but we want to check
        // that we can actually scroll down to see instructionsText if its missing
        pllTrainerElements.newUserStartPage.instructionsText.assertConsumableViaVerticalScroll(
          pllTrainerElements.newUserStartPage.container.specifier
        );
        pllTrainerElements.newUserStartPage.learningResources.assertConsumableViaVerticalScroll(
          containerId
        );
        pllTrainerElements.newUserStartPage.cubeStartExplanation.assertConsumableViaVerticalScroll(
          containerId
        );
        pllTrainerElements.newUserStartPage.cubeStartState.assertConsumableViaVerticalScroll(
          containerId
        );
        pllTrainerElements.newUserStartPage.startButton.assertConsumableViaVerticalScroll(
          containerId
        );
        pllTrainerElements.newUserStartPage.editTargetParametersButton.assertConsumableViaVerticalScroll(
          containerId
        );
      });

      it("starts test when pressing space", function () {
        cy.pressKey(Key.space);
        pllTrainerElements.newCasePage.container.assertShows();
      });

      it("starts when pressing the begin button", function () {
        pllTrainerElements.newUserStartPage.startButton.get().click();
        pllTrainerElements.newCasePage.container.assertShows();
      });

      it("doesn't start test when pressing any other keys", function () {
        cy.pressKey(Key.a);
        pllTrainerElements.newUserStartPage.container.assertShows();
        cy.pressKey(Key.x);
        pllTrainerElements.newUserStartPage.container.assertShows();
        cy.pressKey(Key.capsLock);
        pllTrainerElements.newUserStartPage.container.assertShows();
      });

      it("goes to edit target parameters when pressed", function () {
        pllTrainerElements.newUserStartPage.editTargetParametersButton
          .get()
          .click();
        pllTrainerElements.pickTargetParametersPage.container.assertShows();
      });
    });
    context("for a done user", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.startPage.restoreState();
      });
      it("has all the correct elements when displaying statistics", function () {
        // These elements should all display without scrolling
        [
          pllTrainerElements.recurringUserStartPage.numCasesTried,
          pllTrainerElements.recurringUserStartPage.numCasesNotYetTried,
          pllTrainerElements.recurringUserStartPage.worstThreeCases,
          pllTrainerElements.recurringUserStartPage.averageTPS,
          pllTrainerElements.recurringUserStartPage.averageTime,
        ].forEach((x) => {
          x.assertShows();
          x.assertContainedByWindow();
        });
        // These ones we accept possibly having to scroll for so just check it exists
        // We check it's visibility including scroll in the element sizing
        pllTrainerElements.recurringUserStartPage.statisticsShortcomingsExplanation
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.cubeStartExplanation
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.cubeStartState
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.startButton
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.instructionsText
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.learningResources
          .get()
          .should("exist");
        pllTrainerElements.recurringUserStartPage.editTargetParametersButton
          .get()
          .should("exist");

        // A smoke test that we have added some links for the cubing terms
        pllTrainerElements.recurringUserStartPage.container.get().within(() => {
          cy.get("a").should("have.length.above", 0);
        });
      });

      it("sizes elements reasonably when displaying statistics", function () {
        cy.assertNoHorizontalScrollbar();
        const containerSpecifier =
          pllTrainerElements.recurringUserStartPage.container.specifier;
        pllTrainerElements.recurringUserStartPage.statisticsShortcomingsExplanation.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.instructionsText.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.learningResources.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.cubeStartExplanation.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.cubeStartState.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.startButton.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
        pllTrainerElements.recurringUserStartPage.editTargetParametersButton.assertConsumableViaVerticalScroll(
          containerSpecifier
        );
      });

      it("starts test when pressing space", function () {
        cy.pressKey(Key.space);
        pllTrainerElements.testRunning.container.assertShows();
      });

      it("starts when pressing the begin button", function () {
        pllTrainerElements.recurringUserStartPage.startButton.get().click();
        pllTrainerElements.getReadyState.container.assertShows();
      });

      it("doesn't start test when pressing any other keys", function () {
        cy.pressKey(Key.a);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
        cy.pressKey(Key.x);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
        cy.pressKey(Key.capsLock);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
      });

      it("goes to edit target parameters when pressed", function () {
        pllTrainerElements.recurringUserStartPage.editTargetParametersButton
          .get()
          .click();
        pllTrainerElements.pickTargetParametersPage.container.assertShows();
      });
    });
    it("doesn't display statistics when local storage only has picked but not attempted plls", function () {
      cy.setLocalStorage(allPllsPickedLocalStorage);
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
      });
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();
    });

    it("displays welcome text on first visit, and after nearly completed but cancelled test, but not after completing a test fully", function () {
      // Assert no statistics on first visit
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo();
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      // Nearly finish a test
      pllTrainerStatesNewUser.pickAlgorithmPageAfterUnrecoverable.reloadAndNavigateTo(
        {
          navigateOptions: { targetParametersPicked: true },
          retainCurrentLocalStorage: true,
        }
      );

      // Assert still no statistics
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
        navigateOptions: { targetParametersPicked: true },
      });
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      // Finish a test
      pllTrainerStatesNewUser.correctPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
        navigateOptions: { targetParametersPicked: true },
      });

      // Assert statistics now show
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
        navigateOptions: { targetParametersPicked: true },
      });
      pllTrainerElements.recurringUserStartPage.averageTime.assertShows();
      pllTrainerElements.newUserStartPage.welcomeText.assertDoesntExist();
    });

    it("it displays first 1, then 2, then 3, and then 3 results in worst cases for the first 4 algorithms encountered", function () {
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo();
      // Ensure it starts off with no elements
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Aa, {
        aufs: [],
        correct: true,
      });
      assertListHasLength(1);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Ab, {
        aufs: [],
        correct: true,
      });
      assertListHasLength(2);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.H, {
        aufs: [],
        correct: true,
      });
      assertListHasLength(3);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Ga, {
        aufs: [],
        correct: true,
      });
      assertListHasLength(3);

      function assertListHasLength(length: number): void {
        pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
          retainCurrentLocalStorage: true,
        });
        pllTrainerElements.recurringUserStartPage.worstCaseListItem
          .get()
          .should("have.length", length);
      }
    });

    it("displays the correct averages ordered correctly", function () {
      // Taken from the pllToAlgorithmString map
      const AaAlgorithmLength = 10;
      const HAlgorithmLength = 7;
      const ZAlgorithmLength = 9;
      completePLLTestInMilliseconds(1500, PLL.Aa, {
        // Try with no AUFs
        aufs: [],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [{ timeMs: 1500, turns: AaAlgorithmLength }],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.Aa, {
        // Try with a preAUF
        aufs: [AUF.U, AUF.none],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 1500, turns: AaAlgorithmLength },
              // The addition is for the extra AUF turn
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        // Try with a postAUF
        aufs: [AUF.none, AUF.U2],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 1500, turns: AaAlgorithmLength },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      // Ensure with a fourth attempt that only the most recent 3 attempts
      // are taken into account
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        // Try with both AUFs
        aufs: [AUF.UPrime, AUF.U],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.H, {
        aufs: [],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 1000, turns: AaAlgorithmLength + 1 },
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      // Test that DNFs work as we want them to
      completePLLTestInMilliseconds(2000, PLL.Aa, {
        aufs: [AUF.U2, AUF.UPrime],
        correct: false,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.Aa, {
        aufs: [AUF.U2, AUF.none],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        aufs: [AUF.none, AUF.none],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            pll: PLL.Aa,
            dnf: true,
          },
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(3000, PLL.Aa, {
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength }],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });

      /** And here we now test that it correctly calculates statistics for AUFs on symmetric cases */
      /** Note that H-perm is fully symmetrical. Therefore pre-AUF is not a thing, the only
       * difference it makes is changing the post-AUF
       */
      completePLLTestInMilliseconds(2000, PLL.H, {
        // These AUFs actually cancel out and should result in a 0-AUF case
        // and calculated as such
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.H, {
        // These should partially cancel out and just add a single postAUF
        aufs: [AUF.U2, AUF.UPrime],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.H, {
        // This should predictably just add a single turn
        aufs: [AUF.none, AUF.U],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      /**
       * Z is partially symmetrical, having 2 possible preAUFs, either none or a U turn.
       * We just do two tests (after picking the algorithm) to see that these partial
       * symmetries seem handled too
       */
      completePLLTestInMilliseconds(5000, PLL.Z, {
        aufs: [],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [{ timeMs: 5000, turns: ZAlgorithmLength }],
            pll: PLL.Z,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(5000, PLL.Z, {
        // We check that it can indeed get +2
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 5000, turns: ZAlgorithmLength },
              { timeMs: 5000, turns: ZAlgorithmLength + 2 },
            ],
            pll: PLL.Z,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });
      completePLLTestInMilliseconds(5000, PLL.Z, {
        // We check that a U2 postAUF gets correctly cancelled out
        // as one could then just do U' as the preAUF and it's only +1
        aufs: [AUF.U, AUF.U2],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [
              { timeMs: 5000, turns: ZAlgorithmLength },
              { timeMs: 5000, turns: ZAlgorithmLength + 2 },
              { timeMs: 5000, turns: ZAlgorithmLength + 1 },
            ],
            pll: PLL.Z,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: HAlgorithmLength },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
              { timeMs: 2000, turns: HAlgorithmLength + 1 },
            ],
            pll: PLL.H,
          },
          {
            lastThreeResults: [
              { timeMs: 2000, turns: AaAlgorithmLength + 1 },
              { timeMs: 1000, turns: AaAlgorithmLength },
              { timeMs: 3000, turns: AaAlgorithmLength + 2 },
            ],
            pll: PLL.Aa,
          },
        ],
      });

      function assertCorrectStatistics({
        worstCasesFromWorstToBetter,
      }: {
        worstCasesFromWorstToBetter: (
          | {
              lastThreeResults: { timeMs: number; turns: number }[];
              pll: PLL;
              dnf?: undefined;
            }
          | { pll: PLL; dnf: true }
        )[];
      }): void {
        pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
          retainCurrentLocalStorage: true,
        });
        pllTrainerElements.recurringUserStartPage.worstCaseListItem
          .get()
          .should("have.length", worstCasesFromWorstToBetter.length)
          .and((elements) => {
            elements.each((index, elem) => {
              const text = Cypress.$(elem).text();
              const caseInfo = worstCasesFromWorstToBetter[index];
              if (caseInfo === undefined) {
                expect.fail(
                  "Unexpected wrong index when lengths should be the same"
                );
              }
              if (caseInfo.dnf !== true) {
                const { averageTimeMs, averageTPS } = computeAverages(
                  caseInfo.lastThreeResults
                );
                expect(text)
                  .to.match(
                    new RegExp(
                      "\\b" + pllToPllLetters[caseInfo.pll] + "-perm\\b"
                    )
                  )
                  .and.match(
                    new RegExp(
                      "\\b" + (averageTimeMs / 1000).toFixed(2) + "s\\b"
                    )
                  )
                  .and.match(
                    new RegExp("\\b" + averageTPS.toFixed(2) + "\\s?TPS\\b")
                  );
              } else {
                expect(text).to.equal(
                  pllToPllLetters[caseInfo.pll] + "-perm: DNF"
                );
              }
            });
          });
      }
    });
    it("displays the global statistics correctly", function () {
      // Taken from pllToAlgorithmString
      // It counts the first x rotation but not the last one
      const AaAlgorithmLength = 10;
      const GaAlgorithmLength = 12;
      const totalPLLCases = 21;
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo();
      pllTrainerElements.newUserStartPage.container.waitFor();
      pllTrainerElements.recurringUserStartPage.numCasesTried.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.numCasesNotYetTried.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.averageTPS.assertDoesntExist();

      completePLLTestInMilliseconds(1000, PLL.Aa, {
        aufs: [AUF.UPrime, AUF.none],
        correct: true,
      });
      assertCorrectGlobalStatistics({
        numTried: 1,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
        ],
      });

      completePLLTestInMilliseconds(2000, PLL.Ab, {
        aufs: [],
        correct: false,
      });
      // Still counts a try even though it's incorrect.
      // But doesn't change the global averages
      assertCorrectGlobalStatistics({
        numTried: 2,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
        ],
      });

      completePLLTestInMilliseconds(2000, PLL.Ga, {
        aufs: [AUF.U, AUF.U2],
        correct: true,
      });
      // And counts a third one after an incorrect
      // And now changes the global averages
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [{ timeMs: 2000, turns: GaAlgorithmLength + 2 }],
        ],
      });

      completePLLTestInMilliseconds(1000, PLL.Ga, {
        aufs: [],
        correct: true,
      });
      // And doesn't count a repeat of one we tried before in numTried
      // but does modify one of the averages
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [
            { timeMs: 2000, turns: GaAlgorithmLength + 2 },
            { timeMs: 1000, turns: GaAlgorithmLength },
          ],
        ],
      });

      // Now we make sure that it only counts the last three by going up
      // to 4 tests on Ga
      completePLLTestInMilliseconds(2000, PLL.Ga, {
        aufs: [AUF.none, AUF.U],
        correct: true,
      });
      completePLLTestInMilliseconds(3000, PLL.Ga, {
        aufs: [AUF.UPrime, AUF.U2],
        correct: true,
      });
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [
            { timeMs: 1000, turns: GaAlgorithmLength },
            { timeMs: 2000, turns: GaAlgorithmLength + 1 },
            { timeMs: 3000, turns: GaAlgorithmLength + 2 },
          ],
        ],
      });

      function assertCorrectGlobalStatistics({
        numTried,
        casesWithLastThreeCasesValid,
      }: {
        numTried: number;
        casesWithLastThreeCasesValid: { timeMs: number; turns: number }[][];
      }): void {
        const eachCasePrecomputed = casesWithLastThreeCasesValid.map(
          computeAverages
        );
        const globalTimeAverageSeconds =
          average(eachCasePrecomputed.map((x) => x.averageTimeMs)) / 1000;
        const globalTPSAverage = average(
          eachCasePrecomputed.map((x) => x.averageTPS)
        );
        const numNotYetTried = totalPLLCases - numTried;
        pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
          retainCurrentLocalStorage: true,
        });
        pllTrainerElements.recurringUserStartPage.numCasesTried
          .get()
          .should("include.text", ": " + numTried.toString());
        pllTrainerElements.recurringUserStartPage.numCasesNotYetTried
          .get()
          .should("include.text", ": " + numNotYetTried.toString());
        pllTrainerElements.recurringUserStartPage.averageTime
          .get()
          .should(
            "include.text",
            ": " + globalTimeAverageSeconds.toFixed(2) + "s"
          );
        pllTrainerElements.recurringUserStartPage.averageTPS
          .get()
          .should("include.text", ": " + globalTPSAverage.toFixed(2));
      }
    });
    function computeAverages(
      lastThreeResults: { timeMs: number; turns: number }[]
    ): { averageTimeMs: number; averageTPS: number } {
      return {
        averageTimeMs: average(lastThreeResults.map((x) => x.timeMs)),
        averageTPS: average(
          lastThreeResults.map(({ timeMs, turns }) => turns / (timeMs / 1000))
        ),
      };
    }
    function average(l: number[]) {
      return l.reduce((a, b) => a + b) / l.length;
    }
    it("correctly ignores y rotations at beginning and end of algorithm as this can be dealt with through AUFs", function () {
      type Aliases = {
        unmodified: string;
        modified: string;
      };
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        aufs: [AUF.U2, AUF.UPrime],
        correct: true,
        overrideDefaultAlgorithm: pllToAlgorithmString[PLL.Aa],
      });
      pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
      });
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "unmodified">("unmodified");

      cy.clearLocalStorage();
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        aufs: [AUF.U2, AUF.UPrime],
        correct: true,
        overrideDefaultAlgorithm: "y' " + pllToAlgorithmString[PLL.Aa] + " y2",
      });
      pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
        retainCurrentLocalStorage: true,
      });
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "modified">("modified");

      cy.getAliases<Aliases>().should(({ unmodified, modified }) => {
        assertNonFalsyStringsEqual(
          modified,
          unmodified,
          "modified with y rotations should equal unmodified algorithm"
        );
      });
    });

    /* eslint-disable mocha/no-setup-in-describe */
    ([
      {
        testName:
          "displays exactly the same whether there's a y rotation in the beginning or not as it's redundant",
        pll: PLL.Gc,
        algorithmWithRotation: "(y) R2 U' R U' R U R' U R2 D' U R U' R' D",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      },
      {
        testName:
          "displays exactly the same whether there's a U or Dw move in the beginning or not as it's redundant",
        pll: PLL.Gc,
        algorithmWithRotation: "U Dw R2 U' R U' R U R' U R2 D' U R U' R' D",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      },
      {
        testName:
          "displays a case in the standard orientation, even if there's a y rotation in the middle of the algorithm that isn't corrected later",
        pll: PLL.V,
        algorithmWithRotation: "R' U R' U' (y) R' F' R2 U' R' U R' F R F",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R' U R' U' B' R' B2 U' B' U B' R B R",
      },
      {
        testName:
          "displays a case in the standard orientation, even if there's an x rotation in the beginning of the algorithm that isn't corrected later",
        pll: PLL.E,
        algorithmWithRotation: "x U R' U' L U R U' r2 U' R U L U' R' U",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "F R' F' L F R F' r2 F' R F L F' R' F",
      },
      {
        testName:
          "displays a case in the standard orientation, even if there's a z rotation in the beginning of the algorithm that isn't corrected later",
        pll: PLL.V,
        algorithmWithRotation: "z D' R2 D R2 U R' D' R U' R U R' D R U'",
        // The same algorithm but just modified to move the faces without the rotation
        algorithmWithoutRotation: "R' U2 R U2 L U' R' U L' U L U' R U L'",
      },
      {
        testName:
          "displays a case in the standard orientation, even if there's a wide move in the algorithm that isn't corrected later",
        pll: PLL.Jb,
        algorithmWithRotation: "R U2 R' U' R U2 L' U R' U' r",
        // The same algorithm but just added in an x' at the end to correct the orientation
        algorithmWithoutRotation: "R U2 R' U' R U2 L' U R' U' r x'",
      },
    ] as {
      testName: string;
      pll: PLL;
      algorithmWithRotation: string;
      algorithmWithoutRotation: string;
      only?: boolean;
    }[]).forEach(
      /* eslint-enable mocha/no-setup-in-describe */
      ({
        pll,
        algorithmWithRotation,
        algorithmWithoutRotation,
        testName,
        only,
      }) => {
        (only ? it.only : it)(testName, () => {
          type Aliases = {
            withRotation: string;
            withoutRotation: string;
          };
          // First we input the desired algorithm as our chosen one
          completePLLTestInMilliseconds(1000, pll, {
            correct: true,
            overrideDefaultAlgorithm: algorithmWithRotation,
            aufs: [],
          });
          // Then we run the test with that algorithm being used
          completePLLTestInMilliseconds(1000, pll, {
            correct: true,
            aufs: [],
            testRunningCallback: () =>
              pllTrainerElements.testRunning.testCase
                .getStringRepresentationOfCube()
                .setAlias<Aliases, "withRotation">("withRotation"),
          });

          cy.clearLocalStorage();
          // First we input the desired algorithm as our chosen one
          completePLLTestInMilliseconds(1000, pll, {
            correct: true,
            overrideDefaultAlgorithm: algorithmWithoutRotation,
            aufs: [],
          });
          // Then we run the test with that algorithm being used
          completePLLTestInMilliseconds(1000, pll, {
            correct: true,
            aufs: [],
            testRunningCallback: () =>
              pllTrainerElements.testRunning.testCase
                .getStringRepresentationOfCube()
                .setAlias<Aliases, "withoutRotation">("withoutRotation"),
          });

          cy.getAliases<Aliases>().then(({ withRotation, withoutRotation }) => {
            assertNonFalsyStringsEqual(
              withRotation,
              withoutRotation,
              "they should display the same cube no matter about uncorrected rotations in the algorithm"
            );
          });
        });
      }
    );

    it("doesn't display the same cube for same case with algorithms that require different AUFs", function () {
      type Aliases = {
        firstCube: string;
        secondCube: string;
      };
      const pll = PLL.Ua;
      const aufs = [AUF.none, AUF.none] as const;
      const firstAlgorithm = "R2 U' R' U' R U R U R U' R";
      const secondAlgorithm = "R2 U' R2 S R2 S' U R2";

      runTest({
        algorithm: firstAlgorithm,
      });
      // We only record on the second attempt because on the first attempt the app still doesn't
      // know which algorithm you use so it wouldn't make a difference making the test meaningless
      runTest({
        algorithm: firstAlgorithm,
        cubeAlias: "firstCube",
      });

      cy.clearLocalStorage();

      runTest({
        algorithm: secondAlgorithm,
      });
      runTest({
        algorithm: secondAlgorithm,
        cubeAlias: "secondCube",
      });

      cy.getAliases<Aliases>().should(({ firstCube, secondCube }) => {
        assertNonFalsyStringsDifferent(
          firstCube,
          secondCube,
          "These algorithms should have different AUFs required"
        );
      });

      function runTest<Key extends keyof Aliases>({
        algorithm,
        cubeAlias,
      }: {
        algorithm: string;
        cubeAlias?: Key;
      }) {
        completePLLTestInMilliseconds(1000, pll, {
          aufs,
          correct: true,
          overrideDefaultAlgorithm: algorithm,
          ...(cubeAlias === undefined
            ? {}
            : {
                testRunningCallback: () =>
                  pllTrainerElements.testRunning.testCase
                    .getStringRepresentationOfCube()
                    .setAlias<
                      Aliases,
                      Key
                      // Be cheeky with the types here to make it work. It could potentially
                      // introduce some problems down the line for sure but I don't see a much
                      // better choice and at least it's in the tests
                      // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    >(cubeAlias as any),
              }),
        });
      }
    });

    it("correctly calculates the TPS of the first attempt on a case, even though we don't know which AUF was used until the algorithm is input", function () {
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Ua,
        // Standard slice algorithm
        algorithm: "M2 U M' U2 M U M2",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Ua,
        // An algorithm with a different preAUF but same postAUF
        algorithm: "R2 U' R2 S R2 S' U R2",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Gc,
        // Emil's main Gc algorithm (maybe standard?)
        algorithm: "R2 U' R U' R U R' U R2 D' U R U' R' D",
      });
      assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll: PLL.Gc,
        // An algorithm with a different postAUF but same preAUF
        algorithm: "R2' Uw' R U' R U R' Uw R2 y R U' R' y'",
      });

      function assertFirstAttemptIsCalculatedSameAsSecondAttempt({
        pll,
        algorithm,
      }: {
        pll: PLL;
        algorithm: string;
      }) {
        type Aliases = {
          cubeBefore: string;
          statsBefore: string;
          cubeAfter: string;
          statsAfter: string;
          actualAUF: [AUF, AUF];
        };
        const testResultTime = 1000;
        const internalInitialAUFs = [AUF.none, AUF.none] as const;
        cy.clearLocalStorage();
        completePLLTestInMilliseconds(testResultTime, pll, {
          aufs: internalInitialAUFs,
          correct: false,
          overrideDefaultAlgorithm: algorithm,
          testRunningCallback: () =>
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "cubeBefore">("cubeBefore"),
          algorithmDrillerExplanationPageCallback: () =>
            parseAUFsFromDrillerExplanationPage(algorithm).setAlias<
              Aliases,
              "actualAUF"
            >("actualAUF"),
        });
        cy.getSingleAlias<Aliases, "actualAUF">("actualAUF")
          .then((actualAUFs) => {
            cy.clearLocalStorage();
            completePLLTestInMilliseconds(testResultTime, pll, {
              aufs: internalInitialAUFs,
              correct: true,
              overrideDefaultAlgorithm: algorithm,
            });
            completePLLTestInMilliseconds(testResultTime, pll, {
              aufs: actualAUFs,
              correct: true,
              overrideDefaultAlgorithm: algorithm,
              startPageCallback: () =>
                pllTrainerElements.recurringUserStartPage.worstCaseListItem
                  .get()
                  .invoke("text")
                  .setAlias<Aliases, "statsBefore">("statsBefore"),
              testRunningCallback: () =>
                pllTrainerElements.testRunning.testCase
                  .getStringRepresentationOfCube()
                  .setAlias<Aliases, "cubeAfter">("cubeAfter"),
            });
            pllTrainerStatesUserDone.startPage.reloadAndNavigateTo({
              retainCurrentLocalStorage: true,
            });
            pllTrainerElements.recurringUserStartPage.worstCaseListItem
              .get()
              .invoke("text")
              .setAlias<Aliases, "statsAfter">("statsAfter");
            return cy.getAliases<Aliases>();
          })
          .should(({ cubeBefore, statsBefore, cubeAfter, statsAfter }) => {
            assertNonFalsyStringsEqual(
              cubeBefore,
              cubeAfter,
              "cubes should be the same"
            );
            assertNonFalsyStringsEqual(
              statsBefore,
              statsAfter,
              "stats should be the same"
            );
          });
      }
    });
    it("correctly identifies the AUFs of symmetrical cases", function () {
      /**
       * We are deciding here that we prefer less total turns, quarter turns over half turns,
       * postAUFs over preAUFS and clockwise turns over counterclockwise turns if there
       * are multiple AUF combinations that need tiebreaking between. Also special case
       * [U, U'] is preferred over [U', U] just arbitrarily to have a fully defined ordering.
       *
       * As can be seen several factors are arbitrary such as the clockwise tiebreak.
       * This can definitely be changed in the future to be user customizable
       * or adjusted based on CATPS etc.
       */
      // H PERM TESTS - Full symmetry
      // First we make sure the algorithm is picked so AUFs are predictable
      completePLLTestInMilliseconds(1000, PLL.H, {
        aufs: [],
        correct: true,
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // Checking that a preAUF is moved to a postAUF
        aufToSet: [AUF.U, AUF.none],
        aufToExpect: [AUF.none, AUF.U],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // These two should be simplified to a single U postAUF
        aufToSet: [AUF.UPrime, AUF.U2],
        aufToExpect: [AUF.none, AUF.U],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.H,
        // These should cancel out to no AUFs
        aufToSet: [AUF.U2, AUF.U2],
        aufToExpect: [AUF.none, AUF.none],
      });

      // Z PERM TESTS - Half symmetry
      // Again make sure algorithm is picked
      completePLLTestInMilliseconds(1000, PLL.Z, {
        aufs: [],
        correct: true,
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // Checking that [U, U'] is preferred over [U', U]
        aufToSet: [AUF.UPrime, AUF.U],
        aufToExpect: [AUF.U, AUF.UPrime],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // Checking that [U, U] is preferred over [U', U']
        aufToSet: [AUF.UPrime, AUF.UPrime],
        aufToExpect: [AUF.U, AUF.U],
      });
      assertAUFsDisplayedCorrectly({
        pll: PLL.Z,
        // This should be simplified to a single U that has to be preAUF here
        aufToSet: [AUF.UPrime, AUF.U2],
        aufToExpect: [AUF.U, AUF.none],
      });

      function assertAUFsDisplayedCorrectly({
        pll,
        aufToSet,
        aufToExpect,
      }: {
        pll: PLL;
        aufToSet: [AUF, AUF];
        aufToExpect: [AUF, AUF];
      }) {
        completePLLTestInMilliseconds(1000, pll, {
          aufs: aufToSet,
          correct: false,
          algorithmDrillerExplanationPageCallback: () => {
            pllTrainerElements.root
              .getStateAttributeValue()
              .then((stateAttribute) => {
                if (
                  stateAttribute ===
                  pllTrainerElements.root.stateAttributeValues
                    .algorithmDrillerExplanationPage
                ) {
                  parseAUFsFromDrillerExplanationPage(
                    pllToAlgorithmString[pll]
                  ).should("deep.equal", aufToExpect);
                } else {
                  parseAUFsFromWrongPage().should("deep.equal", aufToExpect);
                }
              });
          },
        });
      }
    });
    function parseAUFsFromWrongPage(): Cypress.Chainable<[AUF, AUF]> {
      // This is preeeetttyyy brittle sadly, so if someone finds a better way to accomplish
      // this testing go for it!
      return pllTrainerElements.wrongPage.testCaseName
        .get()
        .invoke("text")
        .then((testCase) => {
          const matches = /(U['2]?)?\s*\[[[a-zA-Z]+-perm\]\s*(U['2]?)?/.exec(
            testCase
          );
          if (matches === null) {
            throw new Error("Seems our brittle auf parsing broke :(");
          }
          const aufStrings: (string | undefined)[] = matches.slice(1);
          const aufs = aufStrings.map((maybeText) => {
            switch (maybeText) {
              case "U":
                return AUF.U;
              case "U2":
                return AUF.U2;
              case "U'":
                return AUF.UPrime;
              default:
                if (maybeText && !maybeText.includes("U")) {
                  throw new Error(
                    "only AUFs on U face supported right now in parseAUFsFromWrongPage, auf was: " +
                      maybeText.toString()
                  );
                }
                return AUF.none;
            }
          });
          if (aufs.length !== 2) {
            throw new Error(
              "There must be exactly 2 elements in the aufs tuple. There instead were " +
                aufs.length.toString()
            );
          }
          return aufs as [AUF, AUF];
        });
    }
    function parseAUFsFromDrillerExplanationPage(
      algorithm: string
    ): Cypress.Chainable<[AUF, AUF]> {
      // This is preeeetttyyy brittle sadly, so if someone finds a better way to accomplish
      // this testing go for it!
      return pllTrainerElements.algorithmDrillerExplanationPage.algorithmToDrill
        .get()
        .invoke("text")
        .then((displayedAlgorithm) => {
          const aufStrings: (string | undefined)[] = displayedAlgorithm
            .split(algorithm)
            .map((x) => x.trim());
          const aufs = aufStrings.map((maybeText) => {
            switch (maybeText) {
              case "U":
                return AUF.U;
              case "U2":
                return AUF.U2;
              case "U'":
                return AUF.UPrime;
              default:
                if (maybeText && !maybeText.includes("U")) {
                  console.log("algorithm", algorithm);
                  console.log("displayedAlgorithm", displayedAlgorithm);
                  console.log("aufStrings", aufStrings);
                  throw new Error(
                    "only AUFs on U face supported right now in parseAUFsFromDrillerExplanationPage, auf was: " +
                      maybeText.toString()
                  );
                }
                return AUF.none;
            }
          });
          if (aufs.length !== 2) {
            console.log("algorithm", algorithm);
            console.log("displayedAlgorithm", displayedAlgorithm);
            console.log("aufStrings", aufStrings);
            console.log("aufs", aufs);
            throw new Error(
              "There must be exactly 2 elements in the aufs tuple. There instead were " +
                aufs.length.toString()
            );
          }
          return aufs as [AUF, AUF];
        });
    }
  });

  describe("Test Running", function () {
    describe("During Test", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.testRunning.restoreState();
      });

      it("has all the correct elements", function () {});

      it("sizes elements reasonably", function () {
        // Get max length timer to stress test content fitting
        getTestRunningWithMaxLengthTimer();

        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
        const minDimension = Math.min(
          Cypress.config().viewportWidth,
          Cypress.config().viewportHeight
        );
        pllTrainerElements.testRunning.timer.get().should((timerElement) => {
          expect(timerElement.height()).to.be.at.least(0.2 * minDimension);
        });
        pllTrainerElements.testRunning.testCase
          .assertShows()
          .and((cubeElement) => {
            expect(
              cubeElement.width(),
              "cube width to fill at least half of screen"
            ).to.be.at.least(minDimension * 0.5 - 1);
            expect(
              cubeElement.height(),
              "cube height to fill at least half of screen"
            ).to.be.at.least(minDimension * 0.5 - 1);
          });
      });

      it("tracks time correctly", function () {
        const startTime = getTestRunningWithMockedTime();

        const second = 1000;
        const minute = 60 * second;
        const hour = 60 * minute;
        // Should start at 0
        pllTrainerElements.testRunning.timer.get().should("have.text", "0.0");
        // Just testing here that nothing happens with small increments
        tick(3);
        pllTrainerElements.testRunning.timer.get().should("have.text", "0.0");
        tick(10);
        pllTrainerElements.testRunning.timer.get().should("have.text", "0.0");
        tick(0.2 * second);
        pllTrainerElements.testRunning.timer.get().should("have.text", "0.2");
        tick(1.3 * second);
        pllTrainerElements.testRunning.timer.get().should("have.text", "1.5");
        // Switch to using time jumps as tick calls all setInterval times in the
        // time interval resulting in slow tests and excessive cpu usage

        // Checking two digit seconds alone
        setTimeTo(19.2 * second + startTime);
        pllTrainerElements.testRunning.timer.get().should("have.text", "19.2");
        // Checking "normal" minute
        setTimeTo(3 * minute + 16.8 * second + startTime);
        pllTrainerElements.testRunning.timer
          .get()
          .should("have.text", "3:16.8");
        // Checking single digit seconds when above minute still shows two digits
        setTimeTo(4 * minute + 7.3 * second + startTime);
        pllTrainerElements.testRunning.timer
          .get()
          .should("have.text", "4:07.3");
        // Check that it shows hours
        setTimeTo(4 * hour + 38 * minute + 45.7 * second + startTime);
        pllTrainerElements.testRunning.timer
          .get()
          .should("have.text", "4:38:45.7");
        // Check that it shows double digits for minutes and seconds when in hours
        setTimeTo(5 * hour + 1 * minute + 4 * second + startTime);
        pllTrainerElements.testRunning.timer
          .get()
          .should("have.text", "5:01:04.0");
        // Just ensuring a ridiculous amount works too, note we don't break it down to days
        setTimeTo(234 * hour + 59 * minute + 18.1 * second + startTime);
        pllTrainerElements.testRunning.timer
          .get()
          .should("have.text", "234:59:18.1");
      });

      describe("ends test correctly", function () {
        it("on clicking anywhere on the screen", function () {
          ([
            "topLeft",
            "top",
            "topRight",
            "right",
            "bottomRight",
            "bottom",
            "bottomLeft",
            "bottom",
            "left",
            "center",
          ] as const).forEach((position) => {
            cy.withOverallNameLogged(
              {
                name: "testingClick",
                displayName: "TESTING CLICK",
                message: position,
              },
              () => {
                cy.mouseClickScreen(position);
                pllTrainerElements.evaluateResult.container.assertShows({
                  log: false,
                });
              }
            );
            cy.withOverallNameLogged(
              {
                name: "resetting state",
                displayName: "RESETTING STATE",
                message: "to testRunning state",
              },
              () => {
                pllTrainerStatesUserDone.testRunning.restoreState({
                  log: false,
                });
              }
            );
          });
        });

        it("on touching the screen over the area where the correct button is", function () {
          // We observed touching on mobile over the place where the button is can trigger the click event
          // on the next screen about 120ms after. So we just test that clicking 150ms (to be safe) after (with mocked time) doesn't
          // take us on to the "Correct Page"
          cy.clock();
          cy.touchScreen("center");
          cy.tick(150);
          // Force stops it from erroring on disabled button
          pllTrainerElements.evaluateResult.correctButton
            .get()
            .click({ force: true });
          pllTrainerElements.evaluateResult.container.assertShows();
        });

        it("on touching the screen over the area where the wrong button is", function () {
          // We observed touching on mobile over the place where the button is can trigger the click event
          // on the next screen about 120ms after. So we just test that clicking 150ms (to be safe) after (with mocked time) doesn't
          // take us on to the "Wrong Page"
          cy.clock();
          cy.touchScreen("center");
          cy.tick(150);
          // Force stops it from erroring on disabled button
          pllTrainerElements.evaluateResult.wrongButton
            .get()
            .click({ force: true });
          pllTrainerElements.evaluateResult.container.assertShows();
        });
      });
    });
  });

  describe("Evaluate Result", function () {
    describe("starting at ignoring key presses state", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.evaluateResult.restoreState();
      });

      it("has all the correct elements", function () {
        pllTrainerElements.evaluateResult.assertAllShow();
      });

      it("sizes elements reasonably", function () {
        // Get max length timer to stress test content fitting
        getTestRunningWithMaxLengthTimer();
        cy.pressKey(Key.space);
        pllTrainerElements.evaluateResult.container.waitFor();

        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
        const minDimension = Math.min(
          Cypress.config().viewportWidth,
          Cypress.config().viewportHeight
        );
        [
          pllTrainerElements.evaluateResult.expectedCubeFront,
          pllTrainerElements.evaluateResult.expectedCubeBack,
        ].forEach((cubeElement) =>
          cubeElement.get().should((jqueryCube) => {
            expect(
              jqueryCube.width(),
              "cube width to fill at least a quarter of min dimension"
            ).to.be.at.least(minDimension / 4);
            expect(
              jqueryCube.height(),
              "cube height to fill at least a quarter of min dimension"
            ).to.be.at.least(minDimension / 4);
            expect(
              jqueryCube.height(),
              "cube height to fill at most half of screen height"
            ).to.be.at.most(Cypress.config().viewportHeight / 2);
          })
        );
        pllTrainerElements.evaluateResult.timeResult
          .get()
          .should((timerElement) => {
            expect(
              timerElement.height(),
              "time result height at least 10% of min dimension"
            ).to.be.at.least(minDimension / 10);
            expect(
              timerElement.height(),
              "time result at most a third of screen height"
            ).to.be.at.most(Cypress.config().viewportHeight / 3);
          });
        [
          pllTrainerElements.evaluateResult.correctButton,
          pllTrainerElements.evaluateResult.wrongButton,
        ].forEach((buttonGetter) => {
          buttonGetter.get().should((buttonElement) => {
            expect(
              buttonElement.height(),
              "button height at least 5% of min dimension"
            ).to.be.at.least(minDimension / 20);
            expect(
              buttonElement.height(),
              "button height at most a third of screen height"
            ).to.be.at.most(Cypress.config().viewportHeight / 3);
          });
        });
      });

      describe("displays the correct time", function () {
        function getEvaluateAfterTestRanFor({
          milliseconds,
        }: {
          milliseconds: number;
        }): void {
          const startTime = getTestRunningWithMockedTime();
          setTimeTo(milliseconds + startTime);
          cy.pressKey(Key.space);
        }

        it("displays the time it was stopped at", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1530 });
          pllTrainerElements.evaluateResult.timeResult
            .get()
            .should("have.text", "1.53");
        });

        it("displays two decimals on a whole second", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1000 });
          pllTrainerElements.evaluateResult.timeResult
            .get()
            .should("have.text", "1.00");
        });

        it("displays two decimals on whole decisecond", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 600 });
          pllTrainerElements.evaluateResult.timeResult
            .get()
            .should("have.text", "0.60");
        });

        it("displays two decimals on single digit centisecond", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1030 });
          pllTrainerElements.evaluateResult.timeResult
            .get()
            .should("have.text", "1.03");
        });

        describe("handles low granularity", function () {
          it("0", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 100 });
            pllTrainerElements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.10");
          });
          it("1", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 110 });
            pllTrainerElements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.11");
          });
          it("2", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 120 });
            pllTrainerElements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.12");
          });
        });
      });
    });
  });

  describe("Type Of Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();
    });

    it("navigates to 'wrong page' displaying the cube displayed under no moves button when it's clicked", function () {
      type Aliases = {
        front: string;
        back: string;
      };
      pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "front">("front");
      pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "back">("back");

      pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();

      assertCubeMatchesAlias<Aliases, "front">(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "back">(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under no moves button when '1' is pressed", function () {
      type Aliases = {
        front: string;
        back: string;
      };
      pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "front">("front");
      pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "back">("back");

      cy.pressKey(Key.one);

      assertCubeMatchesAlias<Aliases, "front">(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "back">(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under nearly there button when it's clicked", function () {
      type Aliases = {
        front: string;
        back: string;
      };
      pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "front">("front");
      pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "back">("back");

      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();

      assertCubeMatchesAlias<Aliases, "front">(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "back">(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under nearly there button when '2' is pressed", function () {
      type Aliases = {
        front: string;
        back: string;
      };
      pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "front">("front");
      pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "back">("back");

      cy.pressKey(Key.two);

      assertCubeMatchesAlias<Aliases, "front">(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "back">(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying a solved cube when unrecoverable button clicked", function () {
      type Aliases = {
        solvedFront: string;
        solvedBack: string;
      };
      pllTrainerStatesUserDone.startPage.reloadAndNavigateTo();
      pllTrainerElements.newUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedFront">("solvedFront");
      cy.overrideCubeDisplayAngle("ubl");
      pllTrainerElements.newUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedBack">("solvedBack");
      cy.overrideCubeDisplayAngle(null);

      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();

      pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();

      assertCubeMatchesAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "solvedBack">(
        "solvedBack",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying a solved cube when '3' is pressed", function () {
      type Aliases = {
        solvedFront: string;
        solvedBack: string;
      };
      pllTrainerStatesUserDone.startPage.reloadAndNavigateTo();
      pllTrainerElements.newUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedFront">("solvedFront");
      cy.overrideCubeDisplayAngle("ubl");
      pllTrainerElements.newUserStartPage.cubeStartState
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "solvedBack">("solvedBack");
      cy.overrideCubeDisplayAngle(null);

      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();

      cy.pressKey(Key.three);

      assertCubeMatchesAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "solvedBack">(
        "solvedBack",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });
  });
});

function getTestRunningWithMockedTime(): number {
  // There are issues with the restore state functionality when mocking time.
  // Specifically surrounding that the code stores timestamps and mocking
  // changes the timestamps to 0 (or another constant), while the restored version
  // may have saved a current real timestamp. Also seems like there may be other issues
  // that we didn't bother investigating further.
  // Therefore we manually go to that state instead of restoring
  // in order to allow for the mocking time.
  pllTrainerStatesUserDone.startPage.restoreState();
  installClock();
  let curTime = 0;
  cy.pressKey(Key.space);
  pllTrainerElements.getReadyState.container.waitFor();
  tick(getReadyWaitTime);
  curTime += getReadyWaitTime;
  pllTrainerElements.testRunning.container.waitFor();
  return curTime;
}

function getTestRunningWithMaxLengthTimer() {
  // We set the timer to double digit hours to test the limits of the width, that seems like it could be plausible
  // for a huge multiblind attempt if we for some reason support that in the future,
  // but three digit hours seems implausible so no need to test that
  const startTime = getTestRunningWithMockedTime();
  // 15 hours
  setTimeTo(1000 * 60 * 60 * 15 + startTime);
  pllTrainerElements.testRunning.timer.get().should("have.text", "15:00:00.0");
}

/**
 * This is no longer relevant as we migrated to using WebGL, but it's
 * worth keeping here in case we want to use something similar again in the future
 */
// function getHtml5Cube(jqueryElement: JQuery<HTMLElement>) {
//   const html = jqueryElement.html();
//   const sanitized = Cypress._.flow(
//     removeAnySVGs,
//     removeTestids,
//     removeSizeSpecifications,
//     sortStyleBlocks,
//     removeRandomClassAttribute,
//     normalizeWhitespace
//   )(html);

//   return sanitized;
// }

// function removeTestids(html: string): string {
//   return html.replaceAll(/data-testid=".+?"/g, "");
// }
// function removeSizeSpecifications(html: string): string {
//   return html.replaceAll(/-?[0-9]+px/g, "px");
// }
// function sortStyleBlocks(html: string): string {
//   return html.replaceAll(
//     /style="(.*?)"/g,
//     (_, styleString: string) =>
//       `style="${styleString
//         .split(";")
//         .map((x) => x.trim())
//         .sort()
//         .join(";")}"`
//   );
// }
// function removeRandomClassAttribute(html: string): string {
//   return html.replaceAll('class=""', "");
// }
// function normalizeWhitespace(html: string): string {
//   return html.replaceAll(/ +/g, " ");
// }
// function removeAnySVGs(html: string): string {
//   return html.replaceAll(/<svg.*?>.*?<\/svg>/g, "");
// }
