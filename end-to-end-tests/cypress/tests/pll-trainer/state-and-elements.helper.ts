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
  typeOfWrongPage: buildElementsCategory({
    container: "type-of-wrong-container",
    noMoveExplanation: "no-move-explanation",
    noMoveButton: "no-move-button",
    noMoveCubeStateFront: "no-move-cube-state-front",
    noMoveCubeStateBack: "no-move-cube-state-back",
    nearlyThereExplanation: "nearly-there-explanation",
    nearlyThereButton: "nearly-there-button",
    nearlyThereCubeStateFront: "nearly-there-cube-state-front",
    nearlyThereCubeStateBack: "nearly-there-cube-state-back",
    unrecoverableExplanation: "unrecoverable-explanation",
    unrecoverableButton: "unrecoverable-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    testCaseName: "test-case-name",
    testCaseFront: "test-case-front",
    testCaseBack: "test-case-back",
    expectedCubeStateText: "expected-cube-state-text",
    expectedCubeStateFront: "expected-cube-state-front",
    expectedCubeStateBack: "expected-cube-state-back",
    nextButton: "next-button",
  }),
  pickAlgorithmPage: buildElementsCategory({
    container: "pick-algorithm-container",
  }),
  globals: buildGlobalsCategory({
    cube: "cube",
    feedbackButton: "feedback-button",
  }),
};

export const pllTrainerStates = buildStates<
  | "startPage"
  | "getReadyScreen"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringKeyPresses"
  | "correctPage"
  | "typeOfWrongPage"
  | "wrongPage"
>(paths.pllTrainer, {
  startPage: {
    name: "startPage",
    getToThatState: () => {},
    waitForStateToAppear: (options) => {
      pllTrainerElements.startPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  getReadyScreen: {
    name: "getReadyScreen",
    getToThatState: (getState, options) => {
      getState("startPage");
      pllTrainerElements.startPage.startButton.get().click(options);
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.getReadyScreen.container.waitFor(options);
    },
  },
  testRunning: {
    name: "testRunning",
    getToThatState: (getState, options) => {
      // We need to have time mocked from start page
      // to programatically pass through the get ready page
      getState("startPage");
      cy.clock();
      pllTrainerElements.startPage.startButton.get().click(options);
      pllTrainerElements.getReadyScreen.container.waitFor(options);
      cy.tick(1000, options);
      cy.clock().then((clock) => clock.restore());
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.testRunning.container.waitFor(options);
      cy.waitForDocumentEventListeners("mousedown", "keydown");
    },
  },
  evaluateResult: {
    name: "evaluateResult",
    getToThatState: (getState, options) => {
      getState("testRunning");
      cy.pressKey(Key.space, options);
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.evaluateResult.container.waitFor(options);
    },
  },
  evaluateResultAfterIgnoringKeyPresses: {
    name: "evaluateResultAfterIgnoringKeyPresses",
    getToThatState: (getState, options) => {
      // We need to have time mocked from test running
      // to programatically pass through the ignoring key presses phase
      getState("testRunning");
      cy.clock();
      cy.pressKey(Key.space, options);
      pllTrainerElements.evaluateResult.container.waitFor(options);
      cy.tick(300, options);
      cy.clock().then((clock) => clock.restore());
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.evaluateResult.container.waitFor(options);
      cy.waitForDocumentEventListeners("keydown", "keyup");
    },
  },
  correctPage: {
    name: "correctPage",
    getToThatState: (getState, options) => {
      getState("evaluateResultAfterIgnoringKeyPresses");
      pllTrainerElements.evaluateResult.correctButton.get().click(options);
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.correctPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  typeOfWrongPage: {
    name: "typeOfWrongPage",
    getToThatState: (getState, options) => {
      getState("evaluateResultAfterIgnoringKeyPresses");
      pllTrainerElements.evaluateResult.wrongButton.get().click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.typeOfWrongPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  wrongPage: {
    name: "wrongPage",
    getToThatState: (getState, options) => {
      getState("typeOfWrongPage");
      pllTrainerElements.typeOfWrongPage.unrecoverableButton
        .get()
        .click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.wrongPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
} as const);
