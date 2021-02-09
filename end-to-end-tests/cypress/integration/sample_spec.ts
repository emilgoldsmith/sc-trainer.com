import { getKeyValue, Key } from "support/keys";

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
        const tests: Cypress.PositionType[] = [
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
        tests.forEach((position) =>
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
