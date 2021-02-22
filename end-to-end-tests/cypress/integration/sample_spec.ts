import { intercept } from "support/hooks";
import { getKeyValue, Key } from "support/keys";

const mousePositions: Cypress.PositionType[] = [
  "center",
  "top",
  "left",
  "right",
  "bottom",
  "topLeft",
  "topRight",
  "bottomRight",
  "bottomLeft",
];

class StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  constructor(private name: string, private getToThatState: () => void) {}

  populateCache() {
    intercept();
    cy.visit("/");
    this.getToThatState();
    return cy
      .getApplicationState(this.name)
      .then((elmModel) => (this.elmModel = elmModel));
  }

  restoreState() {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    return cy.setApplicationState(this.elmModel, this.name);
  }
}
const states = {
  initial: new StateCache("initial", () => {}),
  testRunning: new StateCache("testRunning", () => {
    states.initial.restoreState();
    cy.pressKey(Key.space);
  }),
  evaluateResult: new StateCache("evaluateResult", () => {
    states.testRunning.restoreState();
    cy.pressKey(Key.space);
  }),
} as const;

describe("AlgorithmTrainer", () => {
  before(() => {
    states.initial.populateCache();
  });

  beforeEach(() => {
    cy.visit("/");
    states.initial.restoreState();
    assertBetweenTestsState();
    cy.clock();
  });

  describe("Between Tests", () => {
    it("has all the correct elements", () => {
      assertBetweenTestsState();
    });
    it("starts test when pressing space", () => {
      cy.pressKey(Key.space);
      assertTestRunningState();
    });
    it("doesn't start test when pressing any other keys", () => {
      cy.pressKey(Key.a);
      assertBetweenTestsState();
      cy.pressKey(Key.x);
      assertBetweenTestsState();
      cy.pressKey(Key.capsLock);
      assertBetweenTestsState();
    });
  });

  describe("Test Running", () => {
    before(() => {
      states.testRunning.populateCache();
    });
    beforeEach(() => {
      states.testRunning.restoreState();
      assertTestRunningState();
    });

    it("has all the correct elements", () => {
      assertTestRunningState();
    });

    describe("ends test correctly", () => {
      it.only("on click anywhere", () => {
        mousePositions.forEach((position) => {
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
      describe("on pressing any keyboard key", () => {
        const tests: Key[] = [
          Key.space,
          Key.l,
          Key.five,
          Key.capsLock,
          Key.leftCtrl,
        ];
        tests.forEach((key) =>
          it(`tested with '${getKeyValue(key)}'`, () => {
            cy.pressKey(key);
            assertEvaluateResultState();
          })
        );
      });
      describe("on long-pressing any keyboard key", () => {
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
          it(`tested with '${getKeyValue(key)}'`, () => {
            cy.longPressKey(key);
            assertEvaluateResultState();
          })
        );
      });
    });
  });

  describe("Evaluate Result", () => {
    before(() => {
      states.evaluateResult.populateCache();
    });

    beforeEach(() => {
      states.evaluateResult.restoreState();
      assertEvaluateResultState();
    });

    it("has all the correct elements", () => {
      assertEvaluateResultState();
    });

    describe("doesn't change state when", () => {
      mousePositions.forEach((position) =>
        it(`mouse clicked at ${position}`, () => {
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
        it(`keyboard key '${getKeyValue(key)}' pressed`, () => {
          cy.pressKey(key);
          assertEvaluateResultState();
        })
      );
    });
    describe("approves correctly", () => {
      it("approves on space pressed", () => {
        cy.pressKey(Key.space);
        assertBetweenTestsState();
        assertCorrectEvaluationMessage();
      });
    });
    describe("rejects correctly", () => {
      it("rejects on w key pressed", () => {
        cy.pressKey(Key.w);
        assertBetweenTestsState();
        assertWrongEvaluationMessage();
      });

      it("also rejects if shift + w is pressed", () => {
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

function assertBetweenTestsState() {
  cy.getByTestId("between-tests-container").should("exist");
}

function assertEvaluateResultState() {
  cy.getByTestId("evaluate-test-result-container").should("exist");
}

function assertCorrectEvaluationMessage() {
  cy.getByTestId("correct-evaluation-message").should("exist");
}

function assertWrongEvaluationMessage() {
  cy.getByTestId("wrong-evaluation-message").should("exist");
}
