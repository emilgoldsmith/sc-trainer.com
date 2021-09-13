import { getKeyValue, Key } from "support/keys";
import { installClock, setTimeTo, tick } from "support/clock";
import {
  pllTrainerStatesUserDone,
  pllTrainerElements,
  pllTrainerStatesNewUser,
  completePLLTestInMilliseconds,
} from "./state-and-elements.helper";
import { Element } from "support/elements";
import { paths } from "support/paths";
import {
  applyDefaultIntercepts,
  createFeatureFlagSetter,
} from "support/interceptors";
import {
  AUF,
  aufToAlgorithmString,
  PLL,
  pllToAlgorithmString,
  pllToPllLetters,
} from "support/pll";
import allPllsPickedLocalStorage from "fixtures/local-storage/all-plls-picked.json";

describe("PLL Trainer - Basic Functionality", function () {
  before(function () {
    pllTrainerStatesUserDone.populateAll();
  });

  beforeEach(function () {
    applyDefaultIntercepts();
    cy.visit(paths.pllTrainer);
  });

  describe("Start Page", function () {
    beforeEach(function () {
      pllTrainerStatesUserDone.startPage.restoreState();
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
      pllTrainerElements.newUserStartPage.cubeStartState.get().should("exist");
      pllTrainerElements.newUserStartPage.startButton.get().should("exist");
      pllTrainerElements.newUserStartPage.instructionsText
        .get()
        .should("exist");
      pllTrainerElements.newUserStartPage.learningResources
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
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      pllTrainerElements.testRunning.container.assertShows();
    });

    it("starts when pressing the begin button", function () {
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.getReadyScreen.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      pllTrainerElements.newUserStartPage.container.assertShows();
      cy.pressKey(Key.x);
      pllTrainerElements.newUserStartPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      pllTrainerElements.newUserStartPage.container.assertShows();
    });
  });

  describe("Test Running", function () {
    describe("Get Ready Screen", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.getReadyScreen.restoreState();
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
        pllTrainerStatesUserDone.testRunning.restoreState();
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
                pllTrainerStatesUserDone.testRunning.restoreState({
                  log: false,
                });
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
                pllTrainerStatesUserDone.testRunning.restoreState({
                  log: false,
                });
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
                pllTrainerStatesUserDone.testRunning.restoreState({
                  log: false,
                });
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
                pllTrainerStatesUserDone.testRunning.restoreState();
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

    describe("after ignoring transitions over", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.evaluateResultAfterIgnoringTransitions.restoreState();
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
      pllTrainerStatesUserDone.correctPage.restoreState();
    });

    it("has all the correct elements", function () {
      pllTrainerElements.correctPage.nextButton.assertShows();
      pllTrainerElements.globals.feedbackButton
        .assertShows()
        .parent()
        .within(() => {
          // It should be a link going to a google form
          cy.get("a")
            .should((linkElement) => {
              expect(linkElement.prop("href"), "href")
                .to.be.a("string")
                .and.satisfy(
                  (href: string) => href.startsWith("https://forms.gle/"),
                  "starts with https://forms.gle/"
                );
              // Asserts it opens in new tab
              expect(linkElement.attr("target"), "target").to.equal("_blank");
            })
            .then((link) => {
              // Check that the link actually works
              cy.request(
                link.attr("href") ||
                  "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid"
              )
                .its("status")
                .should("be.at.least", 200)
                .and("be.lessThan", 300);
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
      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      type Aliases = {
        originalCubeFront: string;
        originalCubeBack: string;
        nextCubeFront: string;
        nextCubeBack: string;
      };
      // Go to evaluate to get the "original" cube state
      pllTrainerStatesUserDone.evaluateResultAfterIgnoringTransitions.restoreState();
      cy.log("GETTING ORIGINAL CUBE HTMLS");
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeFront).setAlias<
        Aliases,
        "originalCubeFront"
      >("originalCubeFront");
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeBack).setAlias<
        Aliases,
        "originalCubeBack"
      >("originalCubeBack");
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
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeFront).setAlias<
        Aliases,
        "nextCubeFront"
      >("nextCubeFront");
      getCubeHtml(pllTrainerElements.evaluateResult.expectedCubeBack).setAlias<
        Aliases,
        "nextCubeBack"
      >("nextCubeBack");
      // Navigate to Type Of Wrong for the tests
      cy.tick(500);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      // SETUP DONE

      // Check all elements are present
      pllTrainerElements.typeOfWrongPage.assertAllShow();

      // Check all the cubes look right

      // The cube for 'no moves applied' should be the same state as the previous/original expected cube state
      assertCubeMatchesAlias<Aliases, "originalCubeFront">(
        "originalCubeFront",
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "originalCubeBack">(
        "originalCubeBack",
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
      );
      // The cube for 'nearly there' should look like the expected state if you had
      // solved the case correctly
      assertCubeMatchesAlias<Aliases, "nextCubeFront">(
        "nextCubeFront",
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      );
      assertCubeMatchesAlias<Aliases, "nextCubeBack">(
        "nextCubeBack",
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      );
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("doesn't leave the page on arbitrary key presses", function () {
      // on purpose use some of the ones we often use like space and w
      [Key.space, Key.w, Key.W, Key.five, Key.d, Key.shift].forEach((key) => {
        cy.pressKey(key);
        pllTrainerElements.typeOfWrongPage.container.assertShows();
      });
    });

    it("navigates to 'wrong page' displaying the cube displayed under no moves button when it's clicked", function () {
      type Aliases = {
        front: string;
        back: string;
      };
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
      ).setAlias<Aliases, "front">("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
      ).setAlias<Aliases, "back">("back");

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
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateFront
      ).setAlias<Aliases, "front">("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.noMoveCubeStateBack
      ).setAlias<Aliases, "back">("back");

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
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      ).setAlias<Aliases, "front">("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      ).setAlias<Aliases, "back">("back");

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
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateFront
      ).setAlias<Aliases, "front">("front");
      getCubeHtml(
        pllTrainerElements.typeOfWrongPage.nearlyThereCubeStateBack
      ).setAlias<Aliases, "back">("back");

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
      };
      cy.visit(paths.pllTrainer);
      getCubeHtml(pllTrainerElements.newUserStartPage.cubeStartState).setAlias<
        Aliases,
        "solvedFront"
      >("solvedFront");
      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();

      pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();

      assertCubeMatchesAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesBackOfAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });

    it("navigates to 'wrong page' displaying a solved cube when '3' is pressed", function () {
      type Aliases = {
        solvedFront: string;
      };
      cy.visit(paths.pllTrainer);
      getCubeHtml(pllTrainerElements.newUserStartPage.cubeStartState).setAlias<
        Aliases,
        "solvedFront"
      >("solvedFront");
      pllTrainerStatesUserDone.typeOfWrongPage.restoreState();

      cy.pressKey(Key.three);

      assertCubeMatchesAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateFront
      );
      assertCubeMatchesBackOfAlias<Aliases, "solvedFront">(
        "solvedFront",
        pllTrainerElements.wrongPage.expectedCubeStateBack
      );
    });
  });

  describe("Wrong Page", function () {
    beforeEach(function () {
      pllTrainerStatesUserDone.wrongPage.restoreState();
    });

    it("has all the correct elements", function () {
      type Aliases = {
        testCaseFront: string;
      };
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
      pllTrainerStatesUserDone.testRunning.restoreState();
      getCubeHtml(pllTrainerElements.testRunning.testCase).setAlias<
        Aliases,
        "testCaseFront"
      >("testCaseFront");

      cy.clock();
      cy.mouseClickScreen("center");
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(500);
      pllTrainerElements.evaluateResult.wrongButton.get().click();
      pllTrainerElements.typeOfWrongPage.container.waitFor();
      // It's important we use this button as otherwise
      // expected state is solved state which could avoid catching
      // a bug we actually (nearly) had in production where what was
      // displayed was the expectedCube with the inverse test case applied
      // to it instead of the solved cube with inverse test case
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();

      assertCubeMatchesAlias<Aliases, "testCaseFront">(
        "testCaseFront",
        pllTrainerElements.wrongPage.testCaseFront
      );
      assertCubeMatchesBackOfAlias<Aliases, "testCaseFront">(
        "testCaseFront",
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
  pllTrainerStatesUserDone.startPage.restoreState();
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
      normalizeWhitespace
    )(html);

    return sanitized;
  });
}

function removeTestids(html: string): string {
  return html.replaceAll(/data-testid=".+?"/g, "");
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
function normalizeWhitespace(html: string): string {
  return html.replaceAll(/ +/g, " ");
}
function removeAnySVGs(html: string): string {
  return html.replaceAll(/<svg.*?>.*?<\/svg>/g, "");
}

function assertCubeMatchesAlias<
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(alias: Key, element: Element): void {
  getCubeHtml(element).should((actualHtml) => {
    cy.getSingleAlias<Aliases, Key>(alias).then((wronglyTypedArg) => {
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
      // Don't do a expect().equal as the diff isn't useful anyway
      // and it takes a long time to generate it due to the large strings
      // We just deal with a boolean and a custom message instead
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
 * For now we use it as it allows us to assert the backside of cubes displayed even
 * when we don't have a reference to compare to, but up to next developer's judgement
 * what to do if it breaks because of implementation change.
 *
 * Some of the assumptions it makes:
 * - The html for the front side includes the description of the back side even if
 *   it doesn't display it to the user
 * - The way it shows the backside is by using the exactly same html as for the
 *   front side, but just adding a 'rotateY(180deg) ' to the transform
 */
function assertCubeMatchesBackOfAlias<
  Aliases extends Record<string, unknown>,
  Key extends keyof Aliases
>(alias: Key, element: Element): void {
  getCubeHtml(element).should((actualBacksideHtml) => {
    cy.getSingleAlias<Aliases, Key>(alias).then((wronglyTypedArg) => {
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

const extraIntercepts: Parameters<typeof applyDefaultIntercepts>[0] = {
  extraHtmlModifiers: [createFeatureFlagSetter("displayAlgorithmPicker", true)],
};

// eslint-disable-next-line mocha/max-top-level-suites
describe("Behind Feature Flag", function () {
  before(function () {
    pllTrainerStatesUserDone.populateAll(extraIntercepts);
  });

  beforeEach(function () {
    applyDefaultIntercepts(extraIntercepts);
  });

  describe("Start Page", function () {
    context("for a done user", function () {
      beforeEach(function () {
        pllTrainerStatesUserDone.startPage.reloadAndNavigateTo();
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
      });

      it("starts test when pressing space", function () {
        cy.pressKey(Key.space);
        pllTrainerElements.testRunning.container.assertShows();
      });

      it("starts when pressing the begin button", function () {
        pllTrainerElements.recurringUserStartPage.startButton.get().click();
        pllTrainerElements.getReadyScreen.container.assertShows();
      });

      it("doesn't start test when pressing any other keys", function () {
        cy.pressKey(Key.a);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
        cy.pressKey(Key.x);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
        cy.pressKey(Key.capsLock);
        pllTrainerElements.recurringUserStartPage.container.assertShows();
      });
    });
    it("doesn't display statistics when local storage only has picked but not attempted plls", function () {
      cy.setLocalStorage(allPllsPickedLocalStorage);
      cy.visit(paths.pllTrainer);
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();
    });

    it("displays welcome text on first visit, and after nearly completed but cancelled test, but not after completing a test fully", function () {
      // Assert no statistics on first visit
      cy.visit(paths.pllTrainer);
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      // Nearly finish a test
      pllTrainerStatesNewUser.pickAlgorithmPageAfterUnrecoverable.reloadAndNavigateTo();

      // Assert still no statistics
      cy.visit(paths.pllTrainer);
      pllTrainerElements.newUserStartPage.welcomeText.assertShows();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      // Finish a test
      pllTrainerStatesNewUser.correctPage.reloadAndNavigateTo();

      // Assert statistics now show
      cy.visit(paths.pllTrainer);
      pllTrainerElements.recurringUserStartPage.averageTime.assertShows();
      pllTrainerElements.newUserStartPage.welcomeText.assertDoesntExist();
    });

    it("it displays first 1, then 2, then 3, and then 3 results in worst cases for the first 4 algorithms encountered", function () {
      cy.visit(paths.pllTrainer);
      pllTrainerElements.newUserStartPage.container.waitFor();
      // Ensure it starts off with no elements
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Aa, {
        firstEncounterWithThisPLL: true,
        aufs: [],
        correct: true,
      });
      assertListHasLength(1);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Ab, {
        firstEncounterWithThisPLL: true,
        aufs: [],
        correct: true,
      });
      assertListHasLength(2);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.H, {
        firstEncounterWithThisPLL: true,
        aufs: [],
        correct: true,
      });
      assertListHasLength(3);

      completePLLTestInMilliseconds(Math.random() * 2000 + 2000, PLL.Ga, {
        firstEncounterWithThisPLL: true,
        aufs: [],
        correct: true,
      });
      assertListHasLength(3);

      function assertListHasLength(length: number): void {
        cy.visit(paths.pllTrainer);
        pllTrainerElements.recurringUserStartPage.worstCaseListItem
          .get()
          .should("have.length", length);
      }
    });

    it("displays the correct averages ordered correctly", function () {
      // Taken from the pllToAlgorithmString map
      const AaAlgorithmLength = 11;
      const HAlgorithmLength = 7;
      completePLLTestInMilliseconds(1500, PLL.Aa, {
        firstEncounterWithThisPLL: true,
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
        firstEncounterWithThisPLL: false,
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
        firstEncounterWithThisPLL: false,
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
        firstEncounterWithThisPLL: false,
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
        firstEncounterWithThisPLL: true,
        aufs: [AUF.UPrime, AUF.U2],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            // Only +1 because H perm is fully symmetrical
            // TODO: Do proper tests for symmetric cases
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength + 1 }],
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
        firstEncounterWithThisPLL: false,
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
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength + 1 }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(2000, PLL.Aa, {
        firstEncounterWithThisPLL: false,
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
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength + 1 }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(1000, PLL.Aa, {
        firstEncounterWithThisPLL: false,
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
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength + 1 }],
            pll: PLL.H,
          },
        ],
      });
      completePLLTestInMilliseconds(3000, PLL.Aa, {
        firstEncounterWithThisPLL: false,
        aufs: [AUF.U, AUF.UPrime],
        correct: true,
      });
      assertCorrectStatistics({
        worstCasesFromWorstToBetter: [
          {
            lastThreeResults: [{ timeMs: 2000, turns: HAlgorithmLength + 1 }],
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
        cy.visit(paths.pllTrainer);
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
      const AaAlgorithmLength = 11;
      const GaAlgorithmLength = 15;
      const totalPLLCases = 21;
      cy.visit(paths.pllTrainer);
      pllTrainerElements.newUserStartPage.container.waitFor();
      pllTrainerElements.recurringUserStartPage.numCasesTried.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.numCasesNotYetTried.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.averageTime.assertDoesntExist();
      pllTrainerElements.recurringUserStartPage.averageTPS.assertDoesntExist();

      completePLLTestInMilliseconds(1000, PLL.Aa, {
        firstEncounterWithThisPLL: true,
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
        firstEncounterWithThisPLL: true,
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
        firstEncounterWithThisPLL: true,
        // TODO: This corresponds to no AUFs for first case as we can't really set
        // aufs on the first attempt, we should really fix that
        aufs: [AUF.U2, AUF.U],
        correct: true,
      });
      // And counts a third one after an incorrect
      // And now changes the global averages
      assertCorrectGlobalStatistics({
        numTried: 3,
        casesWithLastThreeCasesValid: [
          [{ timeMs: 1000, turns: AaAlgorithmLength + 1 }],
          [{ timeMs: 2000, turns: GaAlgorithmLength }],
        ],
      });

      completePLLTestInMilliseconds(1000, PLL.Ga, {
        firstEncounterWithThisPLL: false,
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
            { timeMs: 2000, turns: GaAlgorithmLength },
            { timeMs: 1000, turns: GaAlgorithmLength },
          ],
        ],
      });

      // Now we make sure that it only counts the last three by going up
      // to 4 tests on Ga
      completePLLTestInMilliseconds(2000, PLL.Ga, {
        firstEncounterWithThisPLL: false,
        aufs: [AUF.none, AUF.U],
        correct: true,
      });
      completePLLTestInMilliseconds(3000, PLL.Ga, {
        firstEncounterWithThisPLL: false,
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
        cy.visit(paths.pllTrainer);
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
      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo();
      const testCase = [AUF.U2, PLL.Aa, AUF.UPrime] as const;
      cy.setCurrentTestCase(testCase);
      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(pllToAlgorithmString[PLL.Aa] + "{enter}");
      pllTrainerElements.correctPage.container.waitFor();
      cy.visit(paths.pllTrainer);
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "unmodified">("unmodified");

      cy.clearLocalStorage();
      pllTrainerStatesNewUser.evaluateResultAfterIgnoringTransitions.reloadAndNavigateTo();
      cy.setCurrentTestCase(testCase);
      pllTrainerElements.evaluateResult.correctButton.get().click();
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type("y' " + pllToAlgorithmString[PLL.Aa] + " y2{enter}");
      pllTrainerElements.correctPage.container.waitFor();
      cy.visit(paths.pllTrainer);
      pllTrainerElements.recurringUserStartPage.worstCaseListItem
        .get()
        .invoke("text")
        .setAlias<Aliases, "modified">("modified");
      cy.getAliases<Aliases>().should(({ unmodified, modified }) => {
        expect(unmodified).to.not.be.undefined;
        expect(modified).to.not.be.undefined;
        expect(modified).to.deep.equal(unmodified);
      });
    });

    it("doesn't display the same cube for same case with algorithms that require different AUFs", function () {
      type Aliases = {
        firstCube: string;
        secondCube: string;
      };
      const pll = PLL.Ua;
      const aufs = [AUF.none, AUF.none] as const;
      const firstAlgorithm = "R2 U' R' U' R U R U R U' R";
      const secondAlgorithm = "R2 U' R2 S R2 S' U R2";

      runTest({ algorithm: firstAlgorithm, firstEncounterWithThisPLL: true });
      // We only record on the second attempt because on the first attempt the app still doesn't
      // know which algorithm you use so it wouldn't make a difference making the test meaningless
      runTest({
        algorithm: firstAlgorithm,
        firstEncounterWithThisPLL: false,
        cubeAlias: "firstCube",
      });

      cy.clearLocalStorage();

      runTest({ algorithm: secondAlgorithm, firstEncounterWithThisPLL: true });
      runTest({
        algorithm: secondAlgorithm,
        firstEncounterWithThisPLL: false,
        cubeAlias: "secondCube",
      });

      cy.getAliases<Aliases>().should(({ firstCube, secondCube }) => {
        expect(firstCube).to.not.be.undefined;
        expect(secondCube).to.not.be.undefined;
        expect(
          firstCube === secondCube,
          "These algorithms should have different AUFs required"
        ).to.be.false;
      });

      function runTest<Key extends keyof Aliases>({
        algorithm,
        cubeAlias,
        firstEncounterWithThisPLL,
      }: {
        algorithm: string;
        cubeAlias?: Key;
        firstEncounterWithThisPLL: boolean;
      }) {
        completePLLTestInMilliseconds(1000, pll, {
          firstEncounterWithThisPLL,
          aufs,
          correct: true,
          overrideDefaultAlgorithm: algorithm,
          ...(cubeAlias === undefined
            ? {}
            : {
                testRunningCallback: () =>
                  getCubeHtml(pllTrainerElements.testRunning.testCase).setAlias<
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
      type Aliases = {
        cubeBefore: string;
        statsBefore: string;
        cubeAfter: string;
        statsAfter: string;
        actualAUF: [AUF, AUF];
      };
      const testResultTime = 1000;
      const pll = PLL.Ua;
      const internalInitialAUFs = [AUF.none, AUF.none] as const;
      // const algorithm = "R2 U' R' U' R U R U R U' R";
      const algorithm = "R2 U' R2 S R2 S' U R2";
      completePLLTestInMilliseconds(testResultTime, pll, {
        firstEncounterWithThisPLL: true,
        aufs: internalInitialAUFs,
        correct: false,
        overrideDefaultAlgorithm: algorithm,
        testRunningCallback: () =>
          getCubeHtml(pllTrainerElements.testRunning.testCase).setAlias<
            Aliases,
            "cubeBefore"
          >("cubeBefore"),
        wrongPageCallback: () =>
          parseAUFsFromWrongPage().setAlias<Aliases, "actualAUF">("actualAUF"),
      });
      cy.getSingleAlias<Aliases, "actualAUF">("actualAUF")
        .then((actualAUFs) => {
          if (actualAUFs === undefined) {
            throw new Error("AUFs weren't saved to the alias?");
          }
          cy.clearLocalStorage();
          completePLLTestInMilliseconds(testResultTime, pll, {
            firstEncounterWithThisPLL: true,
            aufs: internalInitialAUFs,
            correct: true,
            overrideDefaultAlgorithm: algorithm,
          });
          completePLLTestInMilliseconds(testResultTime, pll, {
            firstEncounterWithThisPLL: false,
            aufs: actualAUFs,
            correct: true,
            overrideDefaultAlgorithm: algorithm,
            startPageCallback: () =>
              pllTrainerElements.recurringUserStartPage.worstCaseListItem
                .get()
                .invoke("text")
                .setAlias<Aliases, "statsBefore">("statsBefore"),
            testRunningCallback: () =>
              getCubeHtml(pllTrainerElements.testRunning.testCase).setAlias<
                Aliases,
                "cubeAfter"
              >("cubeAfter"),
          });
          cy.visit(paths.pllTrainer);
          pllTrainerElements.recurringUserStartPage.worstCaseListItem
            .get()
            .invoke("text")
            .setAlias<Aliases, "statsAfter">("statsAfter");
          return cy.getAliases<Aliases>();
        })
        .should(({ cubeBefore, statsBefore, cubeAfter, statsAfter }) => {
          expect(cubeBefore === cubeAfter, "cubes should be the same").to.be
            .true;
          expect(statsBefore).to.deep.equal(statsAfter);
          // Just for safety
          expect(cubeBefore).to.not.be.undefined;
          expect(cubeAfter).to.not.be.undefined;
          expect(statsBefore).to.not.be.undefined;
          expect(statsAfter).to.not.be.undefined;
        });
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
  });
  describe("Wrong Page", function () {
    it("has the right correct answer text", function () {
      applyDefaultIntercepts(extraIntercepts);
      pllTrainerStatesNewUser.wrongPage.reloadAndNavigateTo();

      // Verify U and U2 display correctly
      const firstTestCase = [AUF.U, PLL.Aa, AUF.U2] as const;
      cy.setCurrentTestCase(firstTestCase);
      pllTrainerElements.wrongPage.testCaseName
        .get()
        .invoke("text")
        .should("match", testCaseToWrongPageRegex(firstTestCase));

      // Verify U' and nothing display correctly, while also trying a different PLL
      const secondTestCase = [AUF.UPrime, PLL.Ab, AUF.none] as const;
      cy.setCurrentTestCase(secondTestCase);
      pllTrainerElements.wrongPage.testCaseName
        .get()
        .invoke("text")
        .should("match", testCaseToWrongPageRegex(secondTestCase));

      // Verify no AUFs displays correctly and also trying a third PLL
      const thirdTestCase = [AUF.none, PLL.H, AUF.none] as const;
      cy.setCurrentTestCase(thirdTestCase);
      pllTrainerElements.wrongPage.testCaseName
        .get()
        .invoke("text")
        .should("match", testCaseToWrongPageRegex(thirdTestCase));
    });
  });
});

function testCaseToWrongPageRegex(testCase: readonly [AUF, PLL, AUF]): RegExp {
  const firstAufString = aufToAlgorithmString[testCase[0]];
  const secondAufString = aufToAlgorithmString[testCase[2]];
  return new RegExp(
    [
      firstAufString && String.raw`\b${firstAufString}\s+`,
      String.raw`[^\b]*${pllToPllLetters[testCase[1]]}[^\b]*`,
      secondAufString && String.raw`\s+${secondAufString}\b`,
    ].join("")
  );
}
