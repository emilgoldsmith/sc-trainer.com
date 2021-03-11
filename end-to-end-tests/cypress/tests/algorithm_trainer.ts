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
        displayName: "NAVIGATING TO STATE",
        message: this.name,
      },
      () => {
        // TODO: Wait for model to be registered with a cy command
        cy.visit("/");
        this.getToThatState({ log: false });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then(
          (elmModel) => (this.elmModel = elmModel)
        );
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

function buildElementsSingle<keys extends string>(
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
  betweenTests: buildElementsSingle({ container: "between-tests-container" }),
  testRunning: buildElementsSingle({
    container: "test-running-container",
    timer: "timer",
  }),
  evaluateResult: buildElementsSingle({
    container: "evaluate-test-result-container",
    correctMessage: "correct-evaluation-message",
    wrongMessage: "wrong-evaluation-message",
  }),
};

const states = {
  initial: new StateCache(
    "initial",
    () => {},
    elements.betweenTests.container.waitFor
  ),
  testRunning: new StateCache(
    "testRunning",
    () => {
      states.initial.restoreState();
      cy.pressKey(Key.space);
    },
    elements.testRunning.container.waitFor
  ),
  evaluateResult: new StateCache(
    "evaluateResult",
    () => {
      states.testRunning.restoreState();
      cy.pressKey(Key.space);
    },
    elements.evaluateResult.container.waitFor
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
      elements.betweenTests.container.assertShows();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
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
      elements.testRunning.container.assertShows();
      elements.testRunning.container.get().within(() => {
        elements.testRunning.timer.assertShows();
      });
    });

    it("tracks time correctly", function () {
      // There are issues with the restore state functionality when mocking time.
      // Specifically surrounding that the code stores timestamps and mocking
      // changes the timestamps to 0 (or another constant), while the restored version
      // may have saved a current timestamp. Also seems like there may be other issues
      // that we didn't bother investigating further.
      // Therefore we manually go to that state instead of restoring
      // in order to allow for the mocking time.
      states.initial.restoreState();
      installClock();
      const second = 1000;
      const minute = 60 * second;
      const hour = 60 * minute;

      cy.pressKey(Key.space);
      elements.testRunning.container.waitFor();
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
      setTimeTo(3 * minute + 16.8 * second);
      elements.testRunning.timer.get().should("have.text", "3:16.8");
      setTimeTo(4 * hour + 38 * minute + 45.7 * second);
      elements.testRunning.timer.get().should("have.text", "4:38:45.7");
      setTimeTo(234 * hour + 59 * minute + 18.1 * second);
      // Just ensuring a ridiculous amount works too, note we don't break it down to days
      elements.testRunning.timer.get().should("have.text", "234:59:18.1");
    });

    describe("ends test correctly", function () {
      it("on click anywhere", function () {
        // We don't need time passing here, and we have suspicions it may
        // cause some flakiness in the test because of the rerenders time causes
        cy.clock();
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
      it("on pressing any keyboard key", function () {
        ([
          Key.space,
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
          // Space is the special one that's the hard case to handle as we're
          // also using space to evaluate a result as correct and the delayed
          // "up" could cause issues
          Key.space,
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
    });
  });

  describe("Evaluate Result", function () {
    beforeEach(function () {
      states.evaluateResult.restoreState();
    });

    it("has all the correct elements", function () {
      elements.evaluateResult.container.assertShows();
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
    describe("approves correctly", function () {
      it("approves on space pressed", function () {
        cy.pressKey(Key.space);
        elements.betweenTests.container.assertShows();
        elements.evaluateResult.correctMessage.assertShows();
      });
    });
    describe("rejects correctly", function () {
      it("on w key pressed", function () {
        cy.pressKey(Key.w);
        elements.betweenTests.container.assertShows();
        elements.evaluateResult.wrongMessage.assertShows();
      });

      it("on shift + w pressed", function () {
        cy.pressKey(Key.W);
        elements.betweenTests.container.assertShows();
        elements.evaluateResult.wrongMessage.assertShows();
      });
    });
  });
});

function buildAsserter(testId: string) {
  return function (options?: { log?: boolean }) {
    cy.getByTestId(testId, options).should("be.visible");
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
  cy.window({ log: false }).then(
    (window) =>
      (clock = (withGlobal(window).install() as unknown) as NonNullable<
        typeof clock
      >)
  );
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
