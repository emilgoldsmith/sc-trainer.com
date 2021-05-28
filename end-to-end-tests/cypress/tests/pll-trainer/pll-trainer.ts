import { getKeyValue, Key } from "support/keys";
import { installClock, setTimeTo, tick } from "support/clock";
import {
  pllTrainerStates,
  pllTrainerElements,
} from "./state-and-elements.helper";
import { paths } from "support/paths";

describe("Algorithm Trainer", function () {
  before(function () {
    pllTrainerStates.populateAll();
  });

  beforeEach(function () {
    cy.visit(paths.pllTrainer);
  });

  describe("Start Page", function () {
    beforeEach(function () {
      pllTrainerStates.startPage.restoreState();
    });

    it("has all the correct elements", function () {
      // These elements should all display without scrolling
      pllTrainerElements.startPage.welcomeText.assertShows();
      pllTrainerElements.startPage.welcomeText.assertContainedByWindow();
      // These ones we accept possibly having to scroll for so just check it exists
      // We check it's visibility including scroll in the element sizing
      pllTrainerElements.startPage.cubeStartExplanation.get().should("exist");
      pllTrainerElements.startPage.cubeStartState.get().should("exist");
      pllTrainerElements.startPage.startButton.get().should("exist");
      pllTrainerElements.startPage.instructionsText.get().should("exist");
      pllTrainerElements.startPage.learningResources.get().should("exist");

      // A smoke test that we have added some links for the cubing terms
      pllTrainerElements.startPage.container.get().within(() => {
        cy.get("a").should("have.length.above", 0);
      });
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      const containerId = pllTrainerElements.startPage.container.testId;
      // This one is allowed vertical scrolling, but we want to check
      // that we can actually scroll down to see instructionsText if its missing
      pllTrainerElements.startPage.instructionsText.assertConsumableViaScroll(
        pllTrainerElements.startPage.container.testId
      );
      pllTrainerElements.startPage.learningResources.assertConsumableViaScroll(
        containerId
      );
      pllTrainerElements.startPage.cubeStartExplanation.assertConsumableViaScroll(
        containerId
      );
      pllTrainerElements.globals.cube.assertConsumableViaScroll(containerId);
      pllTrainerElements.startPage.startButton.assertConsumableViaScroll(
        containerId
      );
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("starts when pressing the begin button", function () {
      pllTrainerElements.startPage.startButton.get().click();
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      pllTrainerElements.startPage.container.assertShows();
      cy.pressKey(Key.x);
      pllTrainerElements.startPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      pllTrainerElements.startPage.container.assertShows();
    });
  });

  describe("Test Running", function () {
    describe("Get Ready Screen", function () {
      beforeEach(function () {
        pllTrainerStates.getReadyScreen.restoreState();
      });

      it("has all the correct elements", function () {
        pllTrainerElements.testRunning.container.assertDoesntExist();
        pllTrainerElements.getReadyScreen.container.assertShows();
        pllTrainerElements.getReadyScreen.getReadyExplanation.assertShows();
      });

      it("sizes elements reasonably", function () {
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      });
    });
    describe("During Test", function () {
      beforeEach(function () {
        pllTrainerStates.testRunning.restoreState();
      });

      it("has all the correct elements", function () {
        pllTrainerElements.testRunning.timer.assertShows();
        // The test case is a cube
        pllTrainerElements.testRunning.testCase.get().within(() => {
          pllTrainerElements.globals.cube.assertShows();
        });
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
        pllTrainerElements.testRunning.testCase.get().within(() => {
          pllTrainerElements.globals.cube.assertShows().and((cubeElement) => {
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
                pllTrainerStates.testRunning.restoreState({ log: false });
              }
            );
          });
        });

        it("on touching anywhere on the screen from a touch device", function () {
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
                name: "testingTouch",
                displayName: "TESTING TOUCH",
                message: position,
              },
              () => {
                cy.touchScreen(position);
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
                pllTrainerStates.testRunning.restoreState({ log: false });
              }
            );
          });
        });

        it("on pressing any keyboard key", function () {
          ([
            // Space, w and W are the important ones as they are also used to evaluate
            Key.space,
            Key.w,
            Key.W,
            Key.l,
            Key.five,
            Key.capsLock,
            Key.leftCtrl,
          ] as const).forEach((key) => {
            cy.withOverallNameLogged(
              {
                name: "testingKey",
                displayName: "TESTING KEY",
                message: getKeyValue(key),
              },
              () => {
                cy.pressKey(key, { log: false });
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
                pllTrainerStates.testRunning.restoreState({ log: false });
              }
            );
          });
        });
        it("on long-pressing any keyboard key", function () {
          cy.clock();
          ([
            // Space, w and W are the important ones as they are also used to evaluate
            Key.space,
            Key.w,
            Key.W,
            Key.l,
            Key.five,
            Key.capsLock,
            Key.leftCtrl,
          ] as const).forEach((key) => {
            cy.withOverallNameLogged(
              {
                displayName: "TESTING KEY",
                message: "'" + getKeyValue(key) + "'",
              },
              () => {
                cy.longPressKey(key, { log: false });
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
                pllTrainerStates.testRunning.restoreState();
              }
            );
          });
        });
        it("on button mash space before w", function () {
          cy.clock();
          cy.buttonMash([
            Key.l,
            Key.five,
            Key.shift,
            Key.space,
            Key.capsLock,
            Key.leftCtrl,
            Key.w,
            Key.W,
          ]);
          pllTrainerElements.evaluateResult.container.assertShows();
        });

        it("on button mash w before space", function () {
          cy.clock();
          cy.buttonMash([
            Key.w,
            Key.W,
            Key.l,
            Key.five,
            Key.shift,
            Key.space,
            Key.capsLock,
            Key.leftCtrl,
          ]);
          pllTrainerElements.evaluateResult.container.assertShows();
        });

        it("on long button mash", function () {
          cy.clock();
          cy.longButtonMash([
            Key.w,
            Key.W,
            Key.l,
            Key.five,
            Key.shift,
            Key.space,
            Key.capsLock,
            Key.leftCtrl,
          ]);
          pllTrainerElements.evaluateResult.container.assertShows();
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
        pllTrainerStates.evaluateResult.restoreState();
      });

      it("has all the correct elements", function () {
        pllTrainerElements.evaluateResult.timeResult.assertShows();
        pllTrainerElements.evaluateResult.expectedCubeFront.get().within(() => {
          pllTrainerElements.globals.cube.assertShows();
        });
        pllTrainerElements.evaluateResult.expectedCubeBack.get().within(() => {
          pllTrainerElements.globals.cube.assertShows();
        });
        pllTrainerElements.evaluateResult.correctButton.assertShows();
        pllTrainerElements.evaluateResult.wrongButton.assertShows();
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
        ].forEach((cubeContainer) =>
          cubeContainer.get().within(() => {
            pllTrainerElements.globals.cube.get().should((cubeElement) => {
              expect(
                cubeElement.width(),
                "cube width to fill at least a quarter of min dimension"
              ).to.be.at.least(minDimension / 4);
              expect(
                cubeElement.height(),
                "cube height to fill at least a quarter of min dimension"
              ).to.be.at.least(minDimension / 4);
              expect(
                cubeElement.height(),
                "cube height to fill at most half of screen height"
              ).to.be.at.most(Cypress.config().viewportHeight / 2);
            });
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

    describe("after ignoring key presses over", function () {
      beforeEach(function () {
        pllTrainerStates.evaluateResultAfterIgnoringKeyPresses.restoreState();
      });

      describe("approves correctly", function () {
        it("on space pressed", function () {
          cy.pressKey(Key.space);
          pllTrainerElements.correctPage.container.assertShows();
        });
        it("on button pressed", function () {
          pllTrainerElements.evaluateResult.correctButton.get().click();
          pllTrainerElements.correctPage.container.assertShows();
        });
      });
      describe("rejects correctly", function () {
        it("on w key pressed", function () {
          cy.pressKey(Key.w);
          pllTrainerElements.wrongPage.container.assertShows();
        });

        it("on shift + w pressed", function () {
          cy.pressKey(Key.W);
          pllTrainerElements.wrongPage.container.assertShows();
        });

        it("on button pressed", function () {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.wrongPage.container.assertShows();
        });
      });

      describe("doesn't change state when", function () {
        it(`mouse clicked anywhere`, function () {
          ([
            "center",
            "top",
            "left",
            "right",
            "bottom",
            "topLeft",
            "topRight",
            "bottomRight",
            "bottomLeft",
          ] as const).forEach((position) => {
            cy.withOverallNameLogged(
              {
                name: "testing click",
                displayName: "TESTING CLICK",
                message: `position ${position}`,
              },
              () => {
                cy.get("body", { log: false }).click(position, { log: false });
                pllTrainerElements.evaluateResult.container.assertShows({
                  log: false,
                });
              }
            );
          });
        });
        it(`keyboard key except space and w pressed`, function () {
          [Key.leftCtrl, Key.five, Key.l].forEach((key) => {
            cy.withOverallNameLogged(
              {
                displayName: "TESTING KEY",
                message: "'" + getKeyValue(key) + "'",
              },
              () => {
                cy.pressKey(key, { log: false });
                pllTrainerElements.evaluateResult.container.assertShows({
                  log: false,
                });
              }
            );
          });
        });
      });
    });
  });
  describe("Correct Page", function () {
    beforeEach(function () {
      pllTrainerStates.correctPage.restoreState();
    });

    it("has all the correct elements", function () {
      pllTrainerElements.correctPage.nextButton.assertShows();
      pllTrainerElements.globals.feedbackButton
        .assertShows()
        .parent()
        .within(() => {
          // It should be a link going to a google form
          cy.get("a").should((linkElement) => {
            expect(linkElement.prop("href"), "href")
              .to.be.a("string")
              .and.satisfy(
                (href: string) => href.startsWith("https://forms.gle/"),
                "starts with https://forms.gle/"
              );
            // Asserts it opens in new tab
            expect(linkElement.attr("target"), "target").to.equal("_blank");
          });
        });
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("starts when pressing the next button", function () {
      pllTrainerElements.correctPage.nextButton.get().click();
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      pllTrainerElements.correctPage.container.assertShows();
      cy.pressKey(Key.x);
      pllTrainerElements.correctPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      pllTrainerElements.correctPage.container.assertShows();
    });
  });

  describe.only("Type Of Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStates.typeOfWrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      pllTrainerElements.typeOfWrongPage.assertAllShow();
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });
  });
  describe("Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStates.wrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      pllTrainerElements.wrongPage.testCaseName.assertShows();
      pllTrainerElements.wrongPage.fullTestCase.get().within(() => {
        pllTrainerElements.globals.cube
          .get()
          .should("have.length", 2)
          .and("be.visible");
      });
      pllTrainerElements.wrongPage.cubeStartExplanation.assertShows();
      pllTrainerElements.wrongPage.cubeStartState.assertShows();
      pllTrainerElements.wrongPage.nextButton.assertShows();
      pllTrainerElements.globals.feedbackButton
        .assertShows()
        .parent()
        .within(() => {
          // It should be a link going to a google form
          cy.get("a").should((linkElement) => {
            expect(linkElement.prop("href"), "href")
              .to.be.a("string")
              .and.satisfy(
                (href: string) => href.startsWith("https://forms.gle/"),
                "starts with https://forms.gle/"
              );
            // Asserts it opens in new tab
            expect(linkElement.attr("target"), "target").to.equal("_blank");
          });
        });
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("starts when pressing the next button", function () {
      pllTrainerElements.wrongPage.nextButton.get().click();
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      pllTrainerElements.wrongPage.container.assertShows();
      cy.pressKey(Key.x);
      pllTrainerElements.wrongPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      pllTrainerElements.wrongPage.container.assertShows();
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
  pllTrainerStates.startPage.restoreState();
  installClock();
  let curTime = 0;
  cy.pressKey(Key.space);
  pllTrainerElements.getReadyScreen.container.waitFor();
  // This has to match exactly with the applications one sadly, so pretty brittle
  const timeForGetReadyTransition = 1000;
  tick(timeForGetReadyTransition);
  curTime += timeForGetReadyTransition;
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
