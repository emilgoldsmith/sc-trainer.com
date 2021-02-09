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

describe("AlgorithmTrainer", () => {
  beforeEach(() => {
    cy.visit("/");
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
    beforeEach(() => {
      cy.pressKey(Key.space);
    });

    it("has all the correct elements", () => {
      assertTestRunningState();
    });

    describe("ends test correctly", () => {
      describe("on click anywhere", () => {
        mousePositions.forEach((position) =>
          it(`tested in ${position}`, () => {
            cy.get("body").click(position);
            assertEvaluateResultState();
          })
        );
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
    beforeEach(() => {
      cy.pressKey(Key.space);
      cy.pressKey(Key.space);
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
        // Assert approved message
      });
    });
    describe("rejects correctly", () => {
      it("rejects on w key pressed", () => {
        cy.pressKey(Key.w);
        assertBetweenTestsState();
        // Assert rejected message
      });
      it("also rejects if shift + w is pressed", () => {
        cy.pressKey(Key.W);
        assertBetweenTestsState();
        // Assert rejected message
      });
    });
  });
});

function assertEvaluateResultState() {
  cy.getByTestId("evaluate-test-result-container");
}

function assertTestRunningState() {
  cy.getByTestId("test-running-container");
}

function assertBetweenTestsState() {
  cy.getByTestId("between-tests-container");
}
