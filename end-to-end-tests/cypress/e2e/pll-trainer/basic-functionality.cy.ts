import { Key } from "support/keys";
import { installClock, setTimeTo, tick } from "support/clock";
import {
  pllTrainerStatesUserDone,
  pllTrainerElements,
  pllTrainerStatesNewUser,
  getReadyWaitTime,
} from "./state-and-elements";
import { paths } from "support/paths";
import { applyDefaultIntercepts } from "support/interceptors";
import { forceReloadAndNavigateIfDotOnlyIsUsed } from "support/mocha-helpers";

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

  describe("Evaluate Result", function () {
    describe("starting at ignoring key presses state", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.evaluateResult.restoreState();
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
});
