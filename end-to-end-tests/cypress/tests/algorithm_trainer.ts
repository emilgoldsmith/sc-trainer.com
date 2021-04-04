import { interceptAddingElmModelObserversAndModifiers } from "support/elm-model-monkey-patching";
import { getKeyValue, Key } from "support/keys";
import { withGlobal } from "@sinonjs/fake-timers";

class StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  constructor(
    private name: string,
    private getToThatState: (options?: { log?: boolean }) => void,
    private waitForStateToAppear: (options?: { log?: boolean }) => void
  ) {}

  populateCache() {
    interceptAddingElmModelObserversAndModifiers();
    cy.withOverallNameLogged(
      {
        displayName: "POPULATING CACHE FOR STATE",
        message: this.name,
      },
      (consolePropsSetter) => {
        // TODO: Wait for model to be registered with a cy command
        cy.visit("/");
        this.getToThatState({ log: false });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then((elmModel) => {
          this.elmModel = elmModel;
          consolePropsSetter({ "Elm Model": elmModel });
        });
      }
    );
  }

  restoreState(options?: { log?: boolean }) {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    // TODO: Wait for model to be registered with a cy command
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }
}

function buildElementsCategory<keys extends string>(
  testIds: { [key in keys]: string }
): {
  [key in keys]: {
    get: ReturnType<typeof buildGetter>;
    waitFor: ReturnType<typeof buildWaiter>;
    assertShows: ReturnType<typeof buildAsserter>;
  };
} {
  return Cypress._.mapValues(testIds, (testId: string) => ({
    get: buildGetter(testId),
    waitFor: buildWaiter(testId),
    assertShows: buildAsserter(testId),
  })) as {
    [key in keys]: {
      get: ReturnType<typeof buildGetter>;
      waitFor: ReturnType<typeof buildWaiter>;
      assertShows: ReturnType<typeof buildAsserter>;
    };
  };
}

const elements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: "cube-start-state",
    startButton: "start-button",
  }),
  testRunning: buildElementsCategory({
    container: "test-running-container",
    timer: "timer",
    testCase: "test-case",
  }),
  evaluateResult: buildElementsCategory({
    container: "evaluate-test-result-container",
    timeResult: "time-result",
    expectedCubeFront: "expected-cube-front",
    expectedCubeBack: "expected-cube-back",
    correctButton: "correct-button",
    wrongButton: "wrong-button",
  }),
  correctPage: buildElementsCategory({
    container: "correct-container",
    nextButton: "next-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    cubeStartState: "cube-start-state",
    nextButton: "next-button",
  }),
  globals: buildElementsCategory({
    cube: "cube",
  }),
};

const states = {
  startPage: new StateCache(
    "startPage",
    () => {},
    () => {
      elements.startPage.container.waitFor();
      cy.waitForDocumentEventListeners("keyup");
    }
  ),
  testRunning: new StateCache(
    "testRunning",
    () => {
      states.startPage.restoreState();
      elements.startPage.startButton.get().click();
    },
    () => {
      elements.testRunning.container.waitFor();
      cy.waitForDocumentEventListeners("mousedown", "keydown");
    }
  ),
  evaluateResult: new StateCache(
    "evaluateResult",
    () => {
      states.testRunning.restoreState();
      cy.pressKey(Key.space);
    },
    () => {
      elements.evaluateResult.container.waitFor();
    }
  ),
  correctPage: new StateCache(
    "correctPage",
    () => {
      states.evaluateResult.restoreState();
      elements.evaluateResult.correctButton.get().click();
    },
    () => {
      elements.correctPage.container.waitFor();
      cy.waitForDocumentEventListeners("keyup");
    }
  ),
} as const;

describe("Algorithm Trainer", function () {
  before(function () {
    states.startPage.populateCache();
    states.testRunning.populateCache();
    states.evaluateResult.populateCache();
    states.correctPage.populateCache();
  });
  beforeEach(function () {
    cy.visit("/");
  });

  describe("Start Page", function () {
    beforeEach(function () {
      states.startPage.restoreState();
    });

    it("has all the correct elements", function () {
      elements.startPage.container.assertShows().within(() => {
        elements.startPage.startButton.assertShows();
        elements.startPage.cubeStartExplanation.assertShows();
        elements.startPage.cubeStartState.get().within(() => {
          elements.globals.cube.assertShows();
        });
      });
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      elements.testRunning.container.assertShows();
    });

    it("starts when pressing the begin button", function () {
      elements.startPage.startButton.get().click();
      elements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      elements.startPage.container.assertShows();
      cy.pressKey(Key.x);
      elements.startPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      elements.startPage.container.assertShows();
    });
  });

  describe("Test Running", function () {
    beforeEach(function () {
      states.testRunning.restoreState();
    });

    it("has all the correct elements", function () {
      elements.testRunning.container.get().within(() => {
        elements.testRunning.timer.assertShows();
        // The test case is a cube
        elements.testRunning.testCase.get().within(() => {
          elements.globals.cube.assertShows();
        });
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
      elements.testRunning.container.get().within(() => {
        elements.testRunning.timer.get().should((timerElement) => {
          expect(timerElement.height()).to.be.at.least(0.2 * minDimension);
        });
        elements.testRunning.testCase.get().within(() => {
          elements.globals.cube.assertShows().and((cubeElement) => {
            expect(
              cubeElement.width(),
              "cube width to fill at least half of screen"
            ).to.be.at.least(minDimension * 0.5);
            expect(
              cubeElement.height(),
              "cube height to fill at least half of screen"
            ).to.be.at.least(minDimension * 0.5);
          });
        });
      });
    });

    it("tracks time correctly", function () {
      getTestRunningWithMockedTime();

      const second = 1000;
      const minute = 60 * second;
      const hour = 60 * minute;
      // Should start at 0
      elements.testRunning.timer.get().should("have.text", "0.0");
      // Just testing here that nothing happens with small increments
      tick(3);
      elements.testRunning.timer.get().should("have.text", "0.0");
      tick(10);
      elements.testRunning.timer.get().should("have.text", "0.0");
      tick(0.2 * second);
      elements.testRunning.timer.get().should("have.text", "0.2");
      tick(1.3 * second);
      elements.testRunning.timer.get().should("have.text", "1.5");
      // Switch to using time jumps as tick calls all setInterval times in the
      // time interval resulting in slow tests and excessive cpu usage

      // Checking two digit seconds alone
      setTimeTo(19.2 * second);
      elements.testRunning.timer.get().should("have.text", "19.2");
      // Checking "normal" minute
      setTimeTo(3 * minute + 16.8 * second);
      elements.testRunning.timer.get().should("have.text", "3:16.8");
      // Checking single digit seconds when above minute still shows two digits
      setTimeTo(4 * minute + 7.3 * second);
      elements.testRunning.timer.get().should("have.text", "4:07.3");
      // Check that it shows hours
      setTimeTo(4 * hour + 38 * minute + 45.7 * second);
      elements.testRunning.timer.get().should("have.text", "4:38:45.7");
      // Check that it shows double digits for minutes and seconds when in hours
      setTimeTo(5 * hour + 1 * minute + 4 * second);
      elements.testRunning.timer.get().should("have.text", "5:01:04.0");
      // Just ensuring a ridiculous amount works too, note we don't break it down to days
      setTimeTo(234 * hour + 59 * minute + 18.1 * second);
      elements.testRunning.timer.get().should("have.text", "234:59:18.1");
    });

    describe("ends test correctly", function () {
      it("on clicking anywhere on the screen", function () {
        // Just proxy "anywhere" as the top left corner
        cy.get("body", { log: false }).click("topLeft");
        elements.evaluateResult.container.assertShows();
      });

      it("on touching the screen from a touch device", function () {
        cy.touch();
        elements.evaluateResult.container.assertShows();
      });

      it.skip("has no delays on touching", function () {
        /**
         * These are sadly the best assertion we can think of to check it doesn't have
         * the annoying delay
         */
        elements.testRunning.container
          .get()
          .should("have.css", "touch-action", "none");
        cy.document().should((document) => {
          const tag = document.head.querySelector(
            'meta[name="viewport"][content]'
          );

          // This should help according to
          // https://developers.google.com/web/updates/2013/12/300ms-tap-delay-gone-away
          expect((tag as Element & { content: string }).content).to.equal(
            "width=device-width"
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
              displayName: "TESTING KEY",
              message: getKeyValue(key),
            },
            () => {
              cy.pressKey(key, { log: false });
              elements.evaluateResult.container.assertShows({ log: false });
            }
          );
          cy.withOverallNameLogged(
            {
              name: "resetting state",
              displayName: "RESETTING STATE",
              message: "to testRunning state",
            },
            () => {
              states.testRunning.restoreState({ log: false });
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
              message: getKeyValue(key),
            },
            () => {
              cy.longPressKey(key, { log: false });
              elements.evaluateResult.container.assertShows({ log: false });
            }
          );
          cy.withOverallNameLogged(
            {
              name: "resetting state",
              displayName: "RESETTING STATE",
              message: "to testRunning state",
            },
            () => {
              states.testRunning.restoreState({ log: false });
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
        elements.evaluateResult.container.assertShows();
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
        elements.evaluateResult.container.assertShows();
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
        elements.evaluateResult.container.assertShows();
      });
    });
  });

  describe("Evaluate Result", function () {
    describe("starting at ignoring key presses state", function () {
      beforeEach(function () {
        states.evaluateResult.restoreState();
      });

      it("has all the correct elements", function () {
        elements.evaluateResult.container.get().within(() => {
          elements.evaluateResult.timeResult.assertShows();
          elements.evaluateResult.expectedCubeFront.get().within(() => {
            elements.globals.cube.assertShows();
          });
          elements.evaluateResult.expectedCubeBack.get().within(() => {
            elements.globals.cube.assertShows();
          });
          elements.evaluateResult.correctButton.assertShows();
          elements.evaluateResult.wrongButton.assertShows();
        });
      });

      it("sizes elements reasonably", function () {
        // Get max length timer to stress test content fitting
        getTestRunningWithMaxLengthTimer();
        cy.pressKey(Key.space);
        elements.evaluateResult.container.waitFor();

        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
        const minDimension = Math.min(
          Cypress.config().viewportWidth,
          Cypress.config().viewportHeight
        );
        elements.evaluateResult.container
          .get()
          // Check contents
          .within(() => {
            [
              elements.evaluateResult.expectedCubeFront,
              elements.evaluateResult.expectedCubeBack,
            ].forEach((cubeContainer) =>
              cubeContainer.get().within(() => {
                elements.globals.cube.get().should((cubeElement) => {
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
            elements.evaluateResult.timeResult.get().should((timerElement) => {
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
              elements.evaluateResult.correctButton,
              elements.evaluateResult.wrongButton,
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
      });

      describe("displays the correct time", function () {
        function getEvaluateAfterTestRanFor({
          milliseconds,
        }: {
          milliseconds: number;
        }): void {
          getTestRunningWithMockedTime();
          setTimeTo(milliseconds);
          cy.pressKey(Key.space);
        }

        it("displays the time it was stopped at", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1530 });
          elements.evaluateResult.timeResult.get().should("have.text", "1.53");
        });

        it("displays two decimals on a whole second", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1000 });
          elements.evaluateResult.timeResult.get().should("have.text", "1.00");
        });

        it("displays two decimals on whole decisecond", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 600 });
          elements.evaluateResult.timeResult.get().should("have.text", "0.60");
        });

        it("displays two decimals on single digit centisecond", function () {
          getEvaluateAfterTestRanFor({ milliseconds: 1030 });
          elements.evaluateResult.timeResult.get().should("have.text", "1.03");
        });

        describe("handles low granularity", function () {
          it("0", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 100 });
            elements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.10");
          });
          it("1", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 110 });
            elements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.11");
          });
          it("2", function () {
            getEvaluateAfterTestRanFor({ milliseconds: 120 });
            elements.evaluateResult.timeResult
              .get()
              .should("have.text", "0.12");
          });
        });
      });
    });

    describe("after ignoring key presses over", function () {
      beforeEach(function () {
        states.testRunning.restoreState();
        cy.clock();
        cy.pressKey(Key.space);
        elements.evaluateResult.container.waitFor();
        cy.tick(300);
        cy.waitForDocumentEventListeners("keydown", "keyup");
        cy.clock().then((c) => c.restore());
      });

      describe("approves correctly", function () {
        it("on space pressed", function () {
          cy.pressKey(Key.space);
          elements.correctPage.container.assertShows();
        });
        it("on button pressed", function () {
          elements.evaluateResult.correctButton.get().click();
          elements.correctPage.container.assertShows();
        });
      });
      describe.skip("rejects correctly", function () {
        it("on w key pressed", function () {
          cy.pressKey(Key.w);
          elements.wrongPage.container.assertShows();
        });

        it("on shift + w pressed", function () {
          cy.pressKey(Key.W);
          elements.wrongPage.container.assertShows();
        });

        it("on button pressed", function () {
          elements.evaluateResult.wrongButton.get().click();
          elements.wrongPage.container.assertShows();
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
                elements.evaluateResult.container.assertShows({ log: false });
              }
            );
          });
        });
        it(`keyboard key except space and w pressed`, function () {
          [Key.leftCtrl, Key.five, Key.l].forEach((key) => {
            cy.withOverallNameLogged(
              {
                displayName: "TESTING KEY",
                message: getKeyValue(key),
              },
              () => {
                cy.pressKey(key, { log: false });
                elements.evaluateResult.container.assertShows({ log: false });
              }
            );
          });
        });
      });
    });
  });
  describe("Correct Page", function () {
    beforeEach(function () {
      states.correctPage.restoreState();
    });

    it("has all the correct elements", function () {
      elements.correctPage.container.get().within(() => {
        elements.correctPage.nextButton.assertShows();
      });
    });

    it("sizes elements reasonably", function () {
      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      elements.testRunning.container.assertShows();
    });

    it("starts when pressing the begin button", function () {
      elements.correctPage.nextButton.get().click();
      elements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      elements.correctPage.container.assertShows();
      cy.pressKey(Key.x);
      elements.correctPage.container.assertShows();
      cy.pressKey(Key.capsLock);
      elements.correctPage.container.assertShows();
    });
  });
});

function getTestRunningWithMockedTime() {
  // There are issues with the restore state functionality when mocking time.
  // Specifically surrounding that the code stores timestamps and mocking
  // changes the timestamps to 0 (or another constant), while the restored version
  // may have saved a current real timestamp. Also seems like there may be other issues
  // that we didn't bother investigating further.
  // Therefore we manually go to that state instead of restoring
  // in order to allow for the mocking time.
  states.startPage.restoreState();
  installClock();
  cy.pressKey(Key.space);
  elements.testRunning.container.waitFor();
}

function getTestRunningWithMaxLengthTimer() {
  // We set the timer to double digit hours to test the limits of the width, that seems like it could be plausible
  // for a huge multiblind attempt if we for some reason support that in the future,
  // but three digit hours seems implausible so no need to test that
  getTestRunningWithMockedTime();
  // 15 hours
  setTimeTo(1000 * 60 * 60 * 15);
  elements.testRunning.timer.get().should("have.text", "15:00:00.0");
}

function buildAsserter(testId: string) {
  return function (options?: { log?: boolean }) {
    return cy.getByTestId(testId, options).should("be.visible");
  };
}

function buildWaiter(testId: string) {
  return function (options?: { log?: boolean }) {
    cy.getByTestId(testId, options);
  };
}

function buildGetter(testId: string) {
  return function (options?: { log?: boolean }) {
    return cy.getByTestId(testId, options);
  };
}

let clock: {
  tick: (ms: number) => number;
  setSystemTime: (now: number) => void;
  next: () => void;
} | null = null;

function getClock(): NonNullable<typeof clock> {
  if (clock === null) {
    throw new Error("Can't call a clock method before you called install");
  }
  return clock;
}
function installClock() {
  cy.window({ log: false }).then((window) => {
    clock = (withGlobal(window).install() as unknown) as NonNullable<
      typeof clock
    >;
  });
}
function tick(ms: number) {
  cy.wrap(undefined, { log: false }).then(() => getClock().tick(ms));
}
function setTimeTo(now: number) {
  cy.wrap(undefined, { log: false }).then(() => {
    const clock = getClock();
    clock.setSystemTime(now);
    clock.next();
  });
}
