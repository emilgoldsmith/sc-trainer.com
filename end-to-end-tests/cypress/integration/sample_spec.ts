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
      cy.pressKey(" ");
      getTestRunning();
    });
    it("doesn't start test when pressing any other keys", () => {
      cy.pressKey("a");
      getBetweenTests();
      cy.pressKey("x");
      getBetweenTests();
      cy.pressKey("CapsLock");
      getBetweenTests();
    });
  });

  describe("Test Running", () => {
    beforeEach(() => {
      cy.pressKey(" ");
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
          cy.pressKey(" ");
          getEvaluateResult();
        });

        it("tested with l", () => {
          cy.pressKey("l");
          getEvaluateResult();
        });

        it("tested with number 5", () => {
          cy.pressKey("5");
          getEvaluateResult();
        });

        it("tested with modifier key caps lock", () => {
          cy.pressKey("CapsLock");
          getEvaluateResult();
        });

        it("tested with modifier key ctrl", () => {
          cy.pressKey("Ctrl");
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
