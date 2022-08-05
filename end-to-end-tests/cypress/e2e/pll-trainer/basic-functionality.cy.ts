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
