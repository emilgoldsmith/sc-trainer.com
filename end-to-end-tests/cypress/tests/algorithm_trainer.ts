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
  betweenTests: buildElementsCategory({
    container: "between-tests-container",
    beginButton: "begin-button",
    correctMessage: "correct-evaluation-message",
    wrongMessage: "wrong-evaluation-message",
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
  }),
  globals: buildElementsCategory({
    cube: "cube",
  }),
};

const states = {
  initial: new StateCache(
    "initial",
    () => {},
    () => {
      elements.betweenTests.container.waitFor();
      cy.waitForDocumentEventListeners("keyup");
    }
  ),
  testRunning: new StateCache(
    "testRunning",
    () => {
      states.initial.restoreState();
      cy.pressKey(Key.space);
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
} as const;

describe("AlgorithmTrainer", function () {
  before(function () {
    states.initial.populateCache();
    states.testRunning.populateCache();
    states.evaluateResult.populateCache();
  });
  beforeEach(function () {
    cy.visit("/");
  });

  describe("Between Tests", function () {
    beforeEach(function () {
      states.initial.restoreState();
    });

    it("has all the correct elements", function () {
      elements.betweenTests.container.assertShows().within(() => {
        elements.betweenTests.beginButton.assertShows();
      });
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      elements.testRunning.container.assertShows();
    });

    it("starts when pressing the begin button", function () {
      elements.betweenTests.beginButton.get().click();
      elements.testRunning.container.assertShows();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      elements.betweenTests.container.assertShows();
      cy.pressKey(Key.x);
      elements.betweenTests.container.assertShows();
      cy.pressKey(Key.capsLock);
      elements.betweenTests.container.assertShows();
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

    it("sizes things approximately correct", function () {
      // We set the timer to double digit hours to test the limits of the width, that seems like it could be plausible
      // for a huge multiblind attempt if we for some reason support that in the future,
      // but three digits seems implausible so no need to test that
      getTestRunningWithMockedTime();
      // 15 hours
      setTimeTo(1000 * 60 * 60 * 15);
      elements.testRunning.timer.get().should("have.text", "15:00:00.0");

      cy.assertNoHorizontalScrollbar();
      cy.assertNoVerticalScrollbar();
      const minDimension = Math.min(
        Cypress.config().viewportWidth,
        Cypress.config().viewportHeight
      );
      elements.testRunning.container
        .get()
        // Check it fills whole screen
        .should((containerElement) => {
          expect(containerElement.width()).to.equal(
            Cypress.config().viewportWidth
          );
          expect(containerElement.height()).to.equal(
            Cypress.config().viewportHeight
          );
        })
        // Check contents
        .within((containerElement) => {
          elements.testRunning.timer.get().should((timerElement) => {
            expect(timerElement.height()).to.be.at.least(0.2 * minDimension);
            expect(timerElement.width()).to.be.at.most(
              // The - 20 is just to ensure there's also always a bit of padding on the sides
              (containerElement.width() as number) - 20
            );
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
        it("approves on space pressed", function () {
          cy.pressKey(Key.space);
          elements.betweenTests.container.assertShows();
          elements.betweenTests.correctMessage.assertShows();
        });
      });
      describe("rejects correctly", function () {
        it("on w key pressed", function () {
          cy.pressKey(Key.w);
          elements.betweenTests.container.assertShows();
          elements.betweenTests.wrongMessage.assertShows();
        });

        it("on shift + w pressed", function () {
          cy.pressKey(Key.W);
          elements.betweenTests.container.assertShows();
          elements.betweenTests.wrongMessage.assertShows();
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
});

function getTestRunningWithMockedTime() {
  // There are issues with the restore state functionality when mocking time.
  // Specifically surrounding that the code stores timestamps and mocking
  // changes the timestamps to 0 (or another constant), while the restored version
  // may have saved a current real timestamp. Also seems like there may be other issues
  // that we didn't bother investigating further.
  // Therefore we manually go to that state instead of restoring
  // in order to allow for the mocking time.
  states.initial.restoreState();
  installClock();
  cy.pressKey(Key.space);
  elements.testRunning.container.waitFor();
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
