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
    cy.visit("/");
    cy.withOverallNameLogged(
      {
        displayName: "NAVIGATING TO STATE",
        message: this.name,
      },
      () => {
        this.getToThatState({ log: false });
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
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }
}

const assertTestRunningState = buildAsserter("test-running-container");
const waitForTestRunningState = buildWaiter("test-running-container");
const assertBetweenTestsState = buildAsserter("between-tests-container");
const waitForBetweenTestsState = buildWaiter("between-tests-container");
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
  beforeEach(function () {
    cy.visit("/");
  });

  describe("Between Tests", function () {
    before(function () {
      states.initial.populateCache();
    });

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
    before(function () {
      states.testRunning.populateCache();
    });

    beforeEach(function () {
      states.testRunning.restoreState();
    });

    it("has all the correct elements", function () {
      assertTestRunningState();
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
              assertTestRunningState({ log: false });
            }
          );
        });
      });
    });
  });

  describe("Evaluate Result", function () {
    before(function () {
      states.evaluateResult.populateCache();
    });

    beforeEach(function () {
      states.evaluateResult.restoreState();
      assertEvaluateResultState();
    });

    it("has all the correct elements", function () {
      assertEvaluateResultState();
    });

    describe("doesn't change state when", function () {
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
      ] as const).forEach((position) =>
        it(`mouse clicked at ${position}`, function () {
          cy.get("body").click(position);
          assertEvaluateResultState();
        })
      );
      // Note we are not including w or space here as those should indeed
      // change the state
      const representativeSelectionOfKeys: Key[] = [
        Key.leftCtrl,
        Key.five,
        Key.l,
      ];
      representativeSelectionOfKeys.forEach((key) =>
        it(`keyboard key '${getKeyValue(key)}' pressed`, function () {
          cy.pressKey(key);
          assertEvaluateResultState();
        })
      );
    });
    describe("approves correctly", function () {
      it("approves on space pressed", function () {
        cy.pressKey(Key.space);
        assertBetweenTestsState();
        assertCorrectEvaluationMessage();
      });
    });
    describe("rejects correctly", function () {
      it("rejects on w key pressed", function () {
        cy.pressKey(Key.w);
        assertBetweenTestsState();
        assertWrongEvaluationMessage();
      });

      it("also rejects if shift + w is pressed", function () {
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
