import { getKeyValue, Key } from "support/keys";

describe("AlgorithmTrainer", () => {
  beforeEach(() => {
    cy.visit("/");
    cy.clock();
  });

  describe("Between Tests", () => {
    it("has all the correct elements", () => {
      getBetweenTests();
    });
    it("starts test when pressing space", () => {
      cy.pressKey(Key.space);
      getTestRunning();
    });
    it("doesn't start test when pressing any other keys", () => {
      cy.pressKey(Key.a);
      getBetweenTests();
      cy.pressKey(Key.x);
      getBetweenTests();
      cy.pressKey(Key.capsLock);
      getBetweenTests();
    });
  });

  describe("Test Running", () => {
    beforeEach(() => {
      cy.pressKey(Key.space);
    });

    it("has all the correct elements", () => {
      getTestRunning();
    });

    describe("ends test", () => {
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
            getEvaluateResult();
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
            getEvaluateResult();
          })
        );
      });
    });
  });
});

function getEvaluateResult() {
  cy.getByTestId("evaluate-test-result-container");
}

function getTestRunning() {
  cy.getByTestId("test-running-container");
}

function getBetweenTests() {
  cy.getByTestId("between-tests-container");
}
