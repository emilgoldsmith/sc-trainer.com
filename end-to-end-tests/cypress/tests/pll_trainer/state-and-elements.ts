import { Key } from "support/keys";
import { buildElementsCategory, buildGlobalsCategory } from "support/elements";
import { buildStates, StateOptions } from "support/state";
import { paths } from "support/paths";

export const pllTrainerElements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    welcomeText: "welcome-text",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: ["cube-start-state", "cube"],
    startButton: "start-button",
    instructionsText: "instructions-text",
    learningResources: "learning-resources",
  }),
  getReadyScreen: buildElementsCategory({
    container: "get-ready-container",
    getReadyExplanation: "get-ready-explanation",
  }),
  testRunning: buildElementsCategory({
    container: "test-running-container",
    timer: "timer",
    testCase: "test-case",
  }),
  evaluateResult: buildElementsCategory({
    container: "evaluate-test-result-container",
    timeResult: "time-result",
    expectedCubeFront: "expected-cube-front",
    expectedCubeBack: "expected-cube-back",
    correctButton: "correct-button",
    wrongButton: "wrong-button",
  }),
  correctPage: buildElementsCategory({
    container: "correct-container",
    nextButton: "next-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    testCaseName: "test-case-name",
    fullTestCase: "full-test-case",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: ["cube-start-state", "cube"],
    nextButton: "next-button",
  }),
  globals: buildGlobalsCategory({
    cube: "cube",
    feedbackButton: "feedback-button",
  }),
};

export const pllTrainerStates = buildStates(paths.pllTrainer, {
  startPage: {
    name: "startPage",
    getToThatState: () => {},
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.startPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  getReadyScreen: {
    name: "getReadyScreen",
    getToThatState: (options?: StateOptions) => {
      pllTrainerStates.startPage.restoreState(options);
      pllTrainerElements.startPage.startButton.get().click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.getReadyScreen.container.waitFor(options);
    },
  },
  testRunning: {
    name: "testRunning",
    getToThatState: (options?: StateOptions) => {
      // We need to have time mocked from start page
      // to programatically pass through the get ready page
      pllTrainerStates.startPage.restoreState(options);
      cy.clock();
      pllTrainerElements.startPage.startButton.get().click(options);
      pllTrainerElements.getReadyScreen.container.waitFor(options);
      cy.tick(1000, options);
      cy.clock().then((clock) => clock.restore());
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.testRunning.container.waitFor(options);
      cy.waitForDocumentEventListeners("mousedown", "keydown");
    },
  },
  evaluateResult: {
    name: "evaluateResult",
    getToThatState: (options?: StateOptions) => {
      pllTrainerStates.testRunning.restoreState(options);
      cy.pressKey(Key.space);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.evaluateResult.container.waitFor(options);
    },
  },
  evaluateResultAfterIgnoringKeyPresses: {
    name: "evaluateResultAfterIgnoringKeyPresses",
    getToThatState: (options?: StateOptions) => {
      // We need to have time mocked from test running
      // to programatically pass through the ignoring key presses phase
      pllTrainerStates.testRunning.restoreState(options);
      cy.clock();
      cy.pressKey(Key.space, options);
      pllTrainerElements.evaluateResult.container.waitFor(options);
      cy.tick(300, options);
      cy.clock().then((clock) => clock.restore());
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.evaluateResult.container.waitFor(options);
      cy.waitForDocumentEventListeners("keydown", "keyup");
    },
  },
  correctPage: {
    name: "correctPage",
    getToThatState: (options?: StateOptions) => {
      pllTrainerStates.evaluateResultAfterIgnoringKeyPresses.restoreState(
        options
      );
      pllTrainerElements.evaluateResult.correctButton.get().click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.correctPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  wrongPage: {
    name: "wrongPage",
    getToThatState: (options?: StateOptions) => {
      pllTrainerStates.evaluateResultAfterIgnoringKeyPresses.restoreState(
        options
      );
      pllTrainerElements.evaluateResult.wrongButton.get().click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.wrongPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
} as const);
