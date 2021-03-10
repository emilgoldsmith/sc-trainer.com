import { interceptAddingElmModelObserversAndModifiers } from "support/elm-model-monkey-patching";
import { getKeyValue, Key } from "support/keys";

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

  restoreState(options?: { log?: false }) {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    // TODO: Wait for model to be registered with a cy command
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }
}

// Between tests
const assertBetweenTestsState = buildAsserter("between-tests-container");
const waitForBetweenTestsState = buildWaiter("between-tests-container");
// Test running
const assertTestRunningState = buildAsserter("test-running-container");
const waitForTestRunningState = buildWaiter("test-running-container");
const getTestRunningContainer = buildGetter("test-running-container");
const assertTimerShows = buildAsserter("timer");
const getTimer = buildGetter("timer");
// Evaluate result
const assertEvaluateResultState = buildAsserter(
  "evaluate-test-result-container"
);
const waitForEvaluateResultState = buildWaiter(
  "evaluate-test-result-container"
);
const assertCorrectEvaluationMessage = buildAsserter(
  "correct-evaluation-message"
);
const assertWrongEvaluationMessage = buildAsserter("wrong-evaluation-message");

const states = {
  initial: new StateCache("initial", () => {}, waitForBetweenTestsState),
  testRunning: new StateCache(
    "testRunning",
    () => {
      states.initial.restoreState();
      cy.pressKey(Key.space);
    },
    waitForTestRunningState
  ),
  evaluateResult: new StateCache(
    "evaluateResult",
    () => {
      states.testRunning.restoreState();
      cy.pressKey(Key.space);
    },
    waitForEvaluateResultState
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
      assertBetweenTestsState();
    });

    it("starts test when pressing space", function () {
      cy.pressKey(Key.space);
      assertTestRunningState();
    });

    it("doesn't start test when pressing any other keys", function () {
      cy.pressKey(Key.a);
      assertBetweenTestsState();
      cy.pressKey(Key.x);
      assertBetweenTestsState();
      cy.pressKey(Key.capsLock);
      assertBetweenTestsState();
    });
  });

  describe("Test Running", function () {
    beforeEach(function () {
      states.testRunning.restoreState();
    });

    it.only("has all the correct elements", function () {
      assertTestRunningState();
      getTestRunningContainer().within(() => {
        assertTimerShows();
      });
    });

    it.only("tracks time correctly", function () {
      // There are issues with the restore state functionality when mocking time.
      // Specifically surrounding that the code stores timestamps and mocking
      // changes the timestamps to 0 (or another constant), while the restored version
      // may have saved a current timestamp. Also seems like there may be other issues
      // that we didn't bother investigating further.
      // Therefore we manually go to that state instead, to allow for the mocking.
      states.initial.restoreState();
      cy.clock();
      const second = 1000;
      const minute = 60 * second;
      const hour = 60 * minute;

      cy.pressKey(Key.space);
      waitForTestRunningState();
      getTimer().should("have.text", "0.0");
      // Just testing here that nothing happens with small increments
      cy.tick(3);
      getTimer().should("have.text", "0.0");
      cy.tick(10);
      getTimer().should("have.text", "0.0");
      // Note that for example doing just 200 milliseconds here failed when it was written.
      // This is because setInterval needs a granularity, so we just use values
      // that seem like "definitely should have been processed here", so with
      // a bit of a buffer.
      cy.tick(0.23 * second);
      getTimer().should("have.text", "0.2");
      cy.tick(1.3 * second);
      getTimer().should("have.text", "1.5");
      cy.tick(3 * minute + 15.3 * second);
      // sum 196843
      getTimer().should("have.text", "3:16.8");
      cy.tick(4 * hour + 35 * minute);
      getTimer().should("have.text", "4:38:16.8");
    });

    describe("ends test correctly", function () {
      it("on click anywhere", function () {
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
              assertEvaluateResultState({ log: false });
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
              assertEvaluateResultState({ log: false });
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
              assertEvaluateResultState({ log: false });
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
      assertEvaluateResultState();
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
              assertEvaluateResultState({ log: false });
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
              assertEvaluateResultState({ log: false });
            }
          );
        });
      });
    });
    describe("approves correctly", function () {
      it("approves on space pressed", function () {
        cy.pressKey(Key.space);
        assertBetweenTestsState();
        assertCorrectEvaluationMessage();
      });
    });
    describe("rejects correctly", function () {
      it("on w key pressed", function () {
        cy.pressKey(Key.w);
        assertBetweenTestsState();
        assertWrongEvaluationMessage();
      });

      it("on shift + w pressed", function () {
        cy.pressKey(Key.W);
        assertBetweenTestsState();
        assertWrongEvaluationMessage();
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
