import { Key } from "support/keys";
import {
  buildElementsCategory,
  buildGlobalsCategory,
  cubeElement,
  anyErrorMessage,
} from "support/elements";
import { buildStates, StateOptions } from "support/state";
import { paths } from "support/paths";

export const pllTrainerElements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    welcomeText: "welcome-text",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: cubeElement("cube-start-state"),
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
    testCase: cubeElement("test-case"),
  }),
  evaluateResult: buildElementsCategory({
    container: "evaluate-test-result-container",
    timeResult: "time-result",
    expectedCubeFront: cubeElement("expected-cube-front"),
    expectedCubeBack: cubeElement("expected-cube-back"),
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
    noMoveCubeStateFront: cubeElement("no-move-cube-state-front"),
    noMoveCubeStateBack: cubeElement("no-move-cube-state-back"),
    nearlyThereExplanation: "nearly-there-explanation",
    nearlyThereButton: "nearly-there-button",
    nearlyThereCubeStateFront: cubeElement("nearly-there-cube-state-front"),
    nearlyThereCubeStateBack: cubeElement("nearly-there-cube-state-back"),
    unrecoverableExplanation: "unrecoverable-explanation",
    unrecoverableButton: "unrecoverable-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    testCaseName: "test-case-name",
    testCaseFront: cubeElement("test-case-front"),
    testCaseBack: cubeElement("test-case-back"),
    expectedCubeStateText: "expected-cube-state-text",
    expectedCubeStateFront: cubeElement("expected-cube-state-front"),
    expectedCubeStateBack: cubeElement("expected-cube-state-back"),
    nextButton: "next-button",
  }),
  pickAlgorithmPage: buildElementsCategory({
    container: "pick-algorithm-container",
    algorithmInput: "algorithm-input",
    anyErrorMessage: anyErrorMessage({ optional: true }),
  }),
  globals: buildGlobalsCategory({
    feedbackButton: "feedback-button",
  }),
};

export const pllTrainerStatesUserDone = buildStates<
  | "startPage"
  | "getReadyScreen"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringTransitions"
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
      pllTrainerElements.startPage.startButton.get(options).click(options);
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
      pllTrainerElements.startPage.startButton.get(options).click(options);
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
  evaluateResultAfterIgnoringTransitions: {
    name: "evaluateResultAfterIgnoringTransitions",
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
      getState("evaluateResultAfterIgnoringTransitions");
      pllTrainerElements.evaluateResult.correctButton
        .get(options)
        .click(options);
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.correctPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  typeOfWrongPage: {
    name: "typeOfWrongPage",
    getToThatState: (getState, options) => {
      getState("evaluateResultAfterIgnoringTransitions");
      pllTrainerElements.evaluateResult.wrongButton.get(options).click(options);
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
        .get(options)
        .click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.wrongPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
} as const);

export const pllTrainerStatesNewUser = buildStates<
  | "startPage"
  | "getReadyScreen"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringTransitions"
  | "pickAlgorithmPage"
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
      pllTrainerElements.startPage.startButton.get(options).click(options);
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
      pllTrainerElements.startPage.startButton.get(options).click(options);
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
  evaluateResultAfterIgnoringTransitions: {
    name: "evaluateResultAfterIgnoringTransitions",
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
  pickAlgorithmPage: {
    name: "pickAlgorithmPage",
    getToThatState: (getState, options) => {
      getState("evaluateResultAfterIgnoringTransitions");
      pllTrainerElements.evaluateResult.correctButton
        .get(options)
        .click(options);
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.pickAlgorithmPage.container.waitFor(options);
    },
  },
  correctPage: {
    name: "correctPage",
    getToThatState: (getState, options) => {
      getState("pickAlgorithmPage");
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get(options)
        .type("U{enter}", { ...options, delay: 0 });
    },
    waitForStateToAppear: (options) => {
      pllTrainerElements.correctPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
  typeOfWrongPage: {
    name: "typeOfWrongPage",
    getToThatState: (getState, options) => {
      getState("evaluateResultAfterIgnoringTransitions");
      pllTrainerElements.evaluateResult.wrongButton.get(options).click(options);
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
        .get(options)
        .click(options);
    },
    waitForStateToAppear: (options?: StateOptions) => {
      pllTrainerElements.wrongPage.container.waitFor(options);
      cy.waitForDocumentEventListeners("keyup");
    },
  },
} as const);
