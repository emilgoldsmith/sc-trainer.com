import { interceptAddingElmModelObserversAndModifiers } from "support/elm-model-monkey-patching";
import { getKeyValue, Key } from "support/keys";

class StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  constructor(
    private name: string,
    private getToThatState: () => void,
    private waitForStateToAppear: () => void
  ) {}

  populateCache() {
    interceptAddingElmModelObserversAndModifiers();
    cy.visit("/");
    this.getToThatState();
    cy.getApplicationState(this.name).then(
      (elmModel) => (this.elmModel = elmModel)
    );
  }

  restoreState() {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    cy.setApplicationState(this.elmModel, this.name);
    this.waitForStateToAppear();
  }
}
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
  });

  beforeEach(function () {
    cy.visit("/");
    states.initial.restoreState();
    assertBetweenTestsState();
    cy.clock();
  });

  describe("Between Tests", function () {
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
      assertTestRunningState();
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
              consoleProps: () => ({ position }),
            },
            () => {
              cy.get("body").click(position);
              assertEvaluateResultState();
            }
          );
          cy.withOverallNameLogged(
            {
              name: "resetting state",
              displayName: "RESETTING STATE",
              message: "to testRunning state",
            },
            () => {
              states.testRunning.restoreState();
              assertTestRunningState();
            }
          );
        });
      });
      describe("on pressing any keyboard key", function () {
        const tests: Key[] = [
          Key.space,
          Key.l,
          Key.five,
          Key.capsLock,
          Key.leftCtrl,
        ];
        tests.forEach((key) =>
          it(`tested with '${getKeyValue(key)}'`, function () {
            cy.pressKey(key);
            assertEvaluateResultState();
          })
        );
      });
      describe("on long-pressing any keyboard key", function () {
        const tests: Key[] = [
          // Space is the special one that's the hard case to handle as we're
          // also using space to evaluate a result as correct and the delayed
          // "up" could cause issues
          Key.space,
          Key.l,
          Key.five,
          Key.capsLock,
          Key.leftCtrl,
        ];
        tests.forEach((key) =>
          it(`tested with '${getKeyValue(key)}'`, function () {
            cy.longPressKey(key);
            assertEvaluateResultState();
          })
        );
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

function assertTestRunningState() {
  cy.getByTestId("test-running-container").should("exist");
}

function waitForTestRunningState() {
  cy.getByTestId("test-running-container");
}

function assertBetweenTestsState() {
  cy.getByTestId("between-tests-container").should("exist");
}

function waitForBetweenTestsState() {
  cy.getByTestId("between-tests-container");
}

function assertEvaluateResultState() {
  cy.getByTestId("evaluate-test-result-container").should("exist");
}

function waitForEvaluateResultState() {
  cy.getByTestId("evaluate-test-result-container");
}

function assertCorrectEvaluationMessage() {
  cy.getByTestId("correct-evaluation-message").should("exist");
}

function assertWrongEvaluationMessage() {
  cy.getByTestId("wrong-evaluation-message").should("exist");
}
