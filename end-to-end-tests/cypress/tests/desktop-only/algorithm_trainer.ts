import { buildElementsCategory } from "support/elements";
import { Key } from "support/keys";

const elements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    startButton: "start-button",
  }),
  getReadyScreen: buildElementsCategory({
    container: "get-ready-container",
  }),
  testRunning: buildElementsCategory({
    container: "test-running-container",
  }),
  evaluateResult: buildElementsCategory({
    container: "evaluate-test-result-container",
    correctButton: "correct-button",
    wrongButton: "wrong-button",
  }),
  correctPage: buildElementsCategory({
    container: "correct-container",
    nextButton: "next-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    nextButton: "next-button",
  }),
};

describe("Algorithm Trainer Desktop Only", function () {
  it("Displays keyboard shortcuts on all buttons", function () {
    cy.visit("/");
    cy.clock();
    elements.startPage.container.waitFor();
    elements.startPage.startButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.pressKey(Key.space);
    elements.getReadyScreen.container.waitFor();
    cy.tick(1000);
    elements.testRunning.container.waitFor();
    cy.pressKey(Key.space);
    elements.evaluateResult.container.waitFor();
    elements.evaluateResult.correctButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.tick(300);
    cy.pressKey(Key.space);
    elements.correctPage.container.waitFor();
    elements.correctPage.nextButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.pressKey(Key.space);
    elements.getReadyScreen.container.waitFor();
    cy.tick(1000);
    elements.testRunning.container.waitFor();

    // And now we go back to evaluateResult so we can do the wrong path
    cy.pressKey(Key.space);
    elements.evaluateResult.container.waitFor();
    elements.evaluateResult.wrongButton
      .get()
      .invoke("text")
      .should("match", /\(\s*[wW]\s*\)/);

    // Note this also checks the w shortcut actually works
    cy.tick(300);
    cy.pressKey(Key.w);
    elements.wrongPage.container.waitFor();
    elements.wrongPage.nextButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Check space actually works as a shortcut too, just to make sure we're
    // asserting the right thing. It's more thoroughly checked in main test
    cy.pressKey(Key.space);
    elements.getReadyScreen.container.waitFor();
  });
});
