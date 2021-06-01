import { getKeyValue, Key } from "support/keys";
import { installClock, setTimeTo, tick } from "support/clock";
import {
  pllTrainerStates,
  pllTrainerElements,
} from "./state-and-elements.helper";
import { Element } from "support/elements";
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
        pllTrainerElements.testRunning.assertAllShow();
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
          cubeElement.get().should((cubeElement) => {
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
          pllTrainerElements.typeOfWrongPage.container.assertShows();
        });

        it("on shift + w pressed", function () {
          cy.pressKey(Key.W);
          pllTrainerElements.typeOfWrongPage.container.assertShows();
        });

        it("on button pressed", function () {
          pllTrainerElements.evaluateResult.wrongButton.get().click();
          pllTrainerElements.typeOfWrongPage.container.assertShows();
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

  describe("Type Of Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStates.typeOfWrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      // LOTS OF SETUP HERE
      const originalCubeFrontAlias = "originalCubeFront";
      const originalCubeBackAlias = "originalCubeBack";
      const nextCubeFrontAlias = "nextCubeFront";
      const nextCubeBackAlias = "nextCubeBack";

      // Go to evaluate to get the "original" cube state
      pllTrainerStates.evaluateResultAfterIgnoringKeyPresses.restoreState();
      cy.log("GETTING ORIGINAL CUBE HTMLS");
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeFront).as(
        originalCubeFrontAlias
      );
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeBack).as(
        originalCubeBackAlias
      );
      // Run another test case
      pllTrainerElements.evaluateResult.correctButton.get().click();
      cy.clock();
      pllTrainerElements.correctPage.nextButton.get().click();
      pllTrainerElements.getReadyScreen.container.waitFor();
      cy.tick(1000);
      pllTrainerElements.testRunning.container.waitFor();
      cy.mouseClickScreen("center");
      // We're back at Evaluate Result
      cy.log("GETTING NEXT CUBE HTMLS");
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeFront).as(
        nextCubeFrontAlias
      );
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeBack).as(
        nextCubeBackAlias
      );
      // Navigate to Type Of Wrong for the tests
      cy.tick(500);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      // SETUP DONE

      // Check all elements are present
      pllTrainerElements.typeOfWrongPage.assertAllShow();

      // Check all the cubes look right

      // no moves cube should be the same state as the previous/original expected cube state
      assertCubeMatchesAlias(
        originalCubeFrontAlias,
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
      );
      assertCubeMatchesAlias(
        originalCubeBackAlias,
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
      );
      // Nearly there cube should look like the expected state if you got it right
      assertCubeMatchesAlias(
        nextCubeFrontAlias,
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      );
      assertCubeMatchesAlias(
        nextCubeBackAlias,
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      );
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("doesn't leave the page on arbitrary key presses", function () {
      // on purpose use some of the ones we often use like space and w
      installClock();
      [Key.space, Key.w, Key.W, Key.five, Key.d, Key.shift].forEach((key) => {
        cy.pressKey(key);
        pllTrainerElements.typeOfWrongPage.container.assertShows();
      });
    });

    it("navigates to 'wrong page' displaying the cube displayed under no moves button when it's clicked", function () {
      getCubeHtml(pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront).as(
        "front"
      );
      getCubeHtml(pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack).as(
        "back"
      );

      pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();

      assertCubeMatchesAlias(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under no moves button when '1' is pressed", function () {
      getCubeHtml(pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront).as(
        "front"
      );
      getCubeHtml(pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack).as(
        "back"
      );

      cy.pressKey(Key.one);

      assertCubeMatchesAlias(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under nearly there button when it's clicked", function () {
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      ).as("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      ).as("back");

      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();

      assertCubeMatchesAlias(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying the cube displayed under nearly there button when '2' is pressed", function () {
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      ).as("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      ).as("back");

      cy.pressKey(Key.two);

      assertCubeMatchesAlias(
        "front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesAlias(
        "back",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying a solved cube when unrecoverable button clicked", function () {
      cy.visit(paths.homePage1);
      getCubeHtml(pllTrainerElements.startPage.cubeStartState).as(
        "solved-front"
      );
      pllTrainerStates.typeOfWrongPage.restoreState();

      pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();

      assertCubeMatchesAlias(
        "solved-front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesBackOfAlias(
        "solved-front",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying a solved cube when '3' is pressed", function () {
      cy.visit(paths.homePage1);
      getCubeHtml(pllTrainerElements.startPage.cubeStartState).as(
        "solved-front"
      );
      pllTrainerStates.typeOfWrongPage.restoreState();

      cy.pressKey(Key.three);

      assertCubeMatchesAlias(
        "solved-front",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesBackOfAlias(
        "solved-front",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });
  });

  describe("Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStates.wrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      pllTrainerElements.wrongPage.assertAllShow();
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

      // Check that the test case cube is actually displaying the case that was tested
      pllTrainerStates.testRunning.restoreState();
      getCubeHtml(pllTrainerElements.testRunning.testCase).as(
        "test-case-front"
      );

      cy.clock();
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(500);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      // It's important we use this button as otherwise
      // expected state is solved state which could avoid catching
      // a bug we actually (nearly) had in production
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();

      assertCubeMatchesAlias(
        "test-case-front",
        pllTrainerElements.wrongPage.testCaseFront
      );
      assertCubeMatchesBackOfAlias(
        "test-case-front",
        pllTrainerElements.wrongPage.testCaseBack
      );
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

function getCubeHtml(element: Element) {
  return element.get().then((jqueryElement) => {
    const html = jqueryElement.html();
    const sanitized = Cypress._.flow(
      removeAnySVGs,
      removeTestids,
      removeSizeSpecifications,
      sortStyleBlocks,
      removeRandomClassAttribute,
      removeAnyDoubleWhitespaces
    )(html);

    return sanitized;
  });
}

function removeTestids(html: string): string {
  return html.replaceAll(/\s*data-testid=".+?"\s*/g, "");
}
function removeSizeSpecifications(html: string): string {
  return html.replaceAll(/-?[0-9]+px/g, "px");
}
function sortStyleBlocks(html: string): string {
  return html.replaceAll(
    /style="(.*?)"/g,
    (_, styleString: string) =>
      `style="${styleString
        .split(";")
        .map((x) => x.trim())
        .sort()
        .join(";")}"`
  );
}
function removeRandomClassAttribute(html: string): string {
  return html.replaceAll('class=""', "");
}
function removeAnyDoubleWhitespaces(html: string): string {
  return html.replaceAll("  ", " ");
}
function removeAnySVGs(html: string): string {
  return html.replaceAll(/<svg.*?>.*?<\/svg>/g, "");
}

function assertCubeMatchesAlias(alias: string, element: Element): void {
  getCubeHtml(element).should((actualHtml) => {
    cy.get("@" + alias).then((wronglyTypedArg) => {
      if (typeof wronglyTypedArg !== "string") {
        throw new Error("html alias was not a string. Alias name was " + alias);
      }
      const expectedHtml: string = wronglyTypedArg;
      if (actualHtml !== expectedHtml) {
        cy.log("Actual and expected HTML Logged To Console");
        console.log("actual html:");
        console.log(actualHtml);
        console.log("expected html:");
        console.log(expectedHtml);
      }
      // Don't do a string "equal" as the diff isn't useful anyway
      // and it takes a long time to generate it due to the large strings
      expect(
        actualHtml === expectedHtml,
        "cube html should equal " + alias + " html"
      ).to.be.true;
    });
  });
}

/**
 * This function is very implementation dependant, much more so than the other cube
 * asserting functions, so could definitely break if the implementation changes.
 * For now we use it as it's not to be able to assert on the back, but up to
 * next developers judgement what to do if it breaks.
 *
 * Some of the assumptions it makes:
 * - The html for the front side includes the description of the back side even if
 *   it doesn't display it to the user
 * - The way it shows the backside is by using the exactly same html as for the
 *   front side, but just adding a 'rotateY(180deg) ' to the transform
 */
function assertCubeMatchesBackOfAlias(alias: string, element: Element): void {
  getCubeHtml(element).should((actualBacksideHtml) => {
    cy.get("@" + alias).then((wronglyTypedArg) => {
      if (typeof wronglyTypedArg !== "string") {
        throw new Error("html alias was not a string. Alias name was " + alias);
      }
      const expectedFrontSideHtml: string = wronglyTypedArg;
      expect(
        actualBacksideHtml !== expectedFrontSideHtml,
        "actual backside shouldn't be equal to front side for alias " + alias
      );
      const actualFrontSideHtml = actualBacksideHtml.replace(
        "rotateY(180deg) ",
        ""
      );
      if (actualFrontSideHtml !== expectedFrontSideHtml) {
        cy.log("Actual and expected HTML Logged To Console");
        console.log("actual front side html:");
        console.log(actualBacksideHtml);
        console.log("expected back side html:");
        console.log(expectedFrontSideHtml);
      }
      expect(
        actualFrontSideHtml === expectedFrontSideHtml,
        "simulated front side of cube html should equal " +
          alias +
          " front side html"
      ).to.be.true;
    });
  });
}
