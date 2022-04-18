import { Key } from "support/keys";
import {
  buildElementsCategory,
  buildGlobalsCategory,
  cubeElement,
  anyErrorMessage,
  errorMessageElement,
  optionalElement,
} from "support/elements";
import { buildStates, StateOptions } from "support/state";
import { paths } from "support/paths";
import { AUF, PLL, pllToAlgorithmString } from "support/pll";
import allPllsAttemptedLocalStorage from "fixtures/local-storage/all-plls-attempted.json";

export const pllTrainerElements = {
  pickTargetParametersPage: buildElementsCategory({
    container: "pick-target-parameters-container",
    explanation: "explanation",
    recognitionTimeInput: "recognition-time-input",
    targetTPSInput: "target-TPS-input",
    submitButton: "submit-button",
    recognitionTimeError: "recognition-time-error",
    tpsError: "tps-error",
  }),
  newUserStartPage: buildElementsCategory({
    container: "start-page-container",
    welcomeText: "welcome-text",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: cubeElement("cube-start-state"),
    startButton: "start-button",
    instructionsText: "instructions-text",
    learningResources: "learning-resources",
  }),
  recurringUserStartPage: buildElementsCategory({
    container: "start-page-container",
    numCasesTried: "num-cases-tried",
    numCasesNotYetTried: "num-cases-not-yet-tried",
    worstThreeCases: "worst-three-cases",
    worstCaseListItem: "worst-case-list-item",
    averageTime: "average-time",
    averageTPS: "average-tps",
    statisticsShortcomingsExplanation: "statistics-shortcomings-explanation",
    cubeStartExplanation: "cube-start-explanation",
    cubeStartState: cubeElement("cube-start-state"),
    startButton: "start-button",
    instructionsText: "instructions-text",
    learningResources: "learning-resources",
  }),
  getReadyState: buildElementsCategory({
    container: "test-running-container-get-ready",
    getReadyOverlay: "get-ready-overlay",
    getReadyExplanation: "get-ready-explanation",
    timer: "timer",
    cubePlaceholder: cubeElement("cube-placeholder"),
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
    explanationText: "explanation-text",
    correctText: optionalElement("correct-text"),
    wrongText: optionalElement("wrong-text"),
    algorithmInput: "algorithm-input",
    submitButton: "submit-button",
    algDbLink: "alg-db-link",
    expertPLLGuidanceLink: "expert-link",
    inputRequiredError: optionalElement(errorMessageElement("input-required")),
    invalidTurnableError: optionalElement(
      errorMessageElement("invalid-turnable")
    ),
    invalidTurnLengthError: optionalElement(
      errorMessageElement("invalid-turn-length")
    ),
    repeatedTurnableError: optionalElement(
      errorMessageElement("repeated-turnable")
    ),
    wideMoveStylesMixedError: optionalElement(
      errorMessageElement("wide-move-styles-mixed")
    ),
    turnWouldWorkWithoutInterruptionError: optionalElement(
      errorMessageElement("turn-would-work-without-interruption")
    ),
    apostropheWrongSideOfLengthError: optionalElement(
      errorMessageElement("apostrophe-wrong-side-of-length")
    ),
    unclosedParenthesisError: optionalElement(
      errorMessageElement("unclosed-parenthesis")
    ),
    unmatchedClosingParenthesisError: optionalElement(
      errorMessageElement("unmatched-closing-parenthesis")
    ),
    emptyParenthesesError: optionalElement(
      errorMessageElement("empty-parentheses")
    ),
    nestedParenthesesError: optionalElement(
      errorMessageElement("nested-parentheses")
    ),
    invalidSymbolError: optionalElement(errorMessageElement("invalid-symbol")),
    algorithmDoesntMatchCaseError: optionalElement(
      errorMessageElement("algorithm-doesnt-match-case")
    ),
  }),
  globals: buildGlobalsCategory({
    anyErrorMessage: anyErrorMessage(),
    feedbackButton: "feedback-button",
  }),
};

export const getReadyWaitTime = 2400;

export const pllTrainerStatesUserDone = buildStates<
  | "startPage"
  | "getReadyState"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringTransitions"
  | "correctPage"
  | "typeOfWrongPage"
  | "wrongPage",
  { case?: [AUF, PLL, AUF] }
>(
  {
    startPath: paths.pllTrainer,
    localStorage: allPllsAttemptedLocalStorage,
    defaultNavigateOptions: {},
  },
  {
    startPage: {
      name: "startPage",
      getToThatState: () => {},
      waitForStateToAppear: (options) => {
        pllTrainerElements.recurringUserStartPage.container.waitFor(options);
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    getReadyState: {
      name: "getReadyState",
      getToThatState: (getState, options) => {
        getState("startPage");
        pllTrainerElements.recurringUserStartPage.startButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.getReadyState.container.waitFor(options);
      },
    },
    testRunning: {
      name: "testRunning",
      getToThatState: (getState, options) => {
        // We need to have time mocked from start page
        // to programatically pass through the get ready page
        getState("startPage");
        cy.clock();
        pllTrainerElements.recurringUserStartPage.startButton
          .get(options)
          .click(options);
        pllTrainerElements.getReadyState.container.waitFor(options);
        cy.tick(getReadyWaitTime, options);
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
        // to programatically pass through the ignoring transitions phase
        getState("testRunning");
        if (options?.case !== undefined) cy.setCurrentTestCase(options.case);
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
        pllTrainerElements.evaluateResult.wrongButton
          .get(options)
          .click(options);
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
  } as const
);

export const pllTrainerStatesNewUser = buildStates<
  | "pickTargetParametersPage"
  | "startPage"
  | "getReadyState"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringTransitions"
  | "pickAlgorithmPageAfterCorrect"
  | "pickAlgorithmPageAfterUnrecoverable"
  | "correctPage"
  | "typeOfWrongPage"
  | "wrongPage",
  // We override the error on the {} type here as the Record<string, never>
  // or Record<string, unknown> break code in different ways and since
  // this generic is always used for & types then it doesn't actually seem to
  // be an issue.
  // eslint-disable-next-line @typescript-eslint/ban-types
  { case: [AUF, PLL, AUF]; algorithm: string } | {}
>(
  { startPath: paths.pllTrainer, defaultNavigateOptions: {}, localStorage: {} },
  {
    pickTargetParametersPage: {
      name: "pickTargetParametersPage",
      getToThatState: () => {},
      waitForStateToAppear: (options) => {
        pllTrainerElements.pickTargetParametersPage.container.waitFor(options);
      },
    },
    startPage: {
      name: "startPage",
      getToThatState: () => {
        pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.newUserStartPage.container.waitFor(options);
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    getReadyState: {
      name: "getReadyState",
      getToThatState: (getState, options) => {
        getState("startPage");
        pllTrainerElements.newUserStartPage.startButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.getReadyState.container.waitFor(options);
      },
    },
    testRunning: {
      name: "testRunning",
      getToThatState: (getState, options) => {
        // We need to have time mocked from start page
        // to programatically pass through the get ready page
        getState("startPage");
        cy.clock();
        pllTrainerElements.newUserStartPage.startButton
          .get(options)
          .click(options);
        pllTrainerElements.getReadyState.container.waitFor(options);
        cy.tick(getReadyWaitTime, options);
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
        if (options && "case" in options && options.case !== undefined)
          cy.setCurrentTestCase(options.case);
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
    pickAlgorithmPageAfterCorrect: {
      name: "pickAlgorithmPageAfterCorrect",
      getToThatState: (getState, options) => {
        getState("evaluateResultAfterIgnoringTransitions");
        pllTrainerElements.evaluateResult.correctButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.pickAlgorithmPage.correctText.waitFor(options);
      },
    },
    correctPage: {
      name: "correctPage",
      getToThatState: (getState, options) => {
        getState("pickAlgorithmPageAfterCorrect");
        cy.setCurrentTestCase([AUF.none, PLL.Aa, AUF.none]);
        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get(options)
          .type(pllToAlgorithmString[PLL.Aa] + "{enter}", {
            ...options,
            delay: 0,
          });
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
        pllTrainerElements.evaluateResult.wrongButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options?: StateOptions) => {
        pllTrainerElements.typeOfWrongPage.container.waitFor(options);
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    pickAlgorithmPageAfterUnrecoverable: {
      name: "pickAlgorithmPageAfterUnrecoverable",
      getToThatState: (getState, options) => {
        getState("typeOfWrongPage");
        pllTrainerElements.typeOfWrongPage.unrecoverableButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.pickAlgorithmPage.wrongText.waitFor(options);
      },
    },
    wrongPage: {
      name: "wrongPage",
      getToThatState: (getState, options) => {
        getState("pickAlgorithmPageAfterUnrecoverable");
        const { case: caseToSet, algorithm } =
          options && "case" in options && options.case !== undefined
            ? options
            : {
                case: [AUF.none, PLL.Aa, AUF.none] as const,
                algorithm: pllToAlgorithmString[PLL.Aa],
              };
        cy.setCurrentTestCase(caseToSet);
        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get(options)
          .type(algorithm + "{enter}", {
            ...options,
            delay: 0,
          });
      },
      waitForStateToAppear: (options?: StateOptions) => {
        pllTrainerElements.wrongPage.container.waitFor(options);
        cy.waitForDocumentEventListeners("keyup");
      },
    },
  } as const
);

export function completePLLTestInMilliseconds(
  milliseconds: number,
  pll: PLL,
  params: {
    firstEncounterWithThisPLL: boolean;
    aufs: readonly [AUF, AUF] | readonly [];
    overrideDefaultAlgorithm?: string;
    startPageCallback?: () => void;
    testRunningCallback?: () => void;
  } & ({ correct: true } | { correct: false; wrongPageCallback?: () => void })
): void {
  const {
    firstEncounterWithThisPLL,
    aufs,
    correct,
    overrideDefaultAlgorithm,
    startPageCallback,
    testRunningCallback,
  } = params;
  const [preAUF, postAUF] = [aufs[0] ?? AUF.none, aufs[1] ?? AUF.none];
  cy.visit(paths.pllTrainer);
  cy.clock();
  pllTrainerElements.newUserStartPage.container.waitFor();
  startPageCallback?.();
  pllTrainerElements.newUserStartPage.startButton.get().click();
  pllTrainerElements.getReadyState.container.waitFor();
  cy.tick(getReadyWaitTime);
  pllTrainerElements.testRunning.container.waitFor();
  cy.setCurrentTestCase([preAUF, pll, postAUF]);
  cy.tick(milliseconds);
  testRunningCallback?.();
  cy.pressKey(Key.space);
  pllTrainerElements.evaluateResult.container.waitFor();
  cy.tick(500);
  cy.clock().then((clock) => clock.restore());
  if (correct) {
    pllTrainerElements.evaluateResult.correctButton.get().click();
  } else {
    pllTrainerElements.evaluateResult.wrongButton.get().click();
    pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
  }
  if (firstEncounterWithThisPLL) {
    pllTrainerElements.pickAlgorithmPage.algorithmInput
      .get()
      .type(
        (overrideDefaultAlgorithm ?? pllToAlgorithmString[pll]) + "{enter}"
      );
  }
  if (correct) pllTrainerElements.correctPage.container.waitFor();
  else {
    pllTrainerElements.wrongPage.container.waitFor();
    params.wrongPageCallback?.();
  }
}
