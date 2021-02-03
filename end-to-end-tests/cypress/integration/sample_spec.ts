import { Key } from "support/keys";

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
        it("tested in center", () => {
          cy.get("body").click("center");
          getEvaluateResult();
        });

        it("tested in top left", () => {
          cy.get("body").click("topLeft");
          getEvaluateResult();
        });
      });
      describe("on pressing any keyboard key", () => {
        it("tested with space", () => {
          cy.pressKey(Key.space);
          getEvaluateResult();
        });

        it("tested with l", () => {
          cy.pressKey(Key.l);
          getEvaluateResult();
        });

        it("tested with number 5", () => {
          cy.pressKey(Key.five);
          getEvaluateResult();
        });

        it("tested with modifier key caps lock", () => {
          cy.pressKey(Key.capsLock);
          getEvaluateResult();
        });

        it("tested with modifier key ctrl", () => {
          cy.pressKey(Key.leftCtrl);
          getEvaluateResult();
        });
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
