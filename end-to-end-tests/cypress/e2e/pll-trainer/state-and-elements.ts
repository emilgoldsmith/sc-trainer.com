import { Key } from "support/keys";
import {
  buildElementsCategory,
  buildGlobalsCategory,
  cubeElement,
  anyErrorMessage,
  errorMessageElement,
  optionalElement,
  buildRootCategory,
} from "support/elements";
import { buildStates, StateOptions } from "support/state";
import { paths } from "support/paths";
import { AUF, PLL, pllToAlgorithmString } from "support/pll";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";

export const pllTrainerElements = {
  root: buildRootCategory({
    testId: "pll-trainer-root",
    stateAttributeValues: {
      pickTargetParametersPage: "pick-target-parameters-page",
      startPage: "start-page",
      newCasePage: "new-case-page",
      getReadyState: "get-ready-state",
      testRunningState: "test-running-state",
      evaluateResultPage: "evaluate-result-page",
      typeOfWrongPage: "type-of-wrong-page",
      pickAlgorithmPage: "pick-algorithm-page",
      algorithmDrillerExplanationPage: "algorithm-driller-explanation-page",
      algorithmDrillerStatusPage: "algorithm-driller-status-page",
      algorithmDrillerSuccessPage: "algorithm-driller-success-page",
      correctPage: "correct-page",
      wrongPage: "wrong-page",
    } as const,
  }),
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
    editTargetParametersButton: "edit-target-parameters-button",
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
    editTargetParametersButton: "edit-target-parameters-button",
  }),
  newCasePage: buildElementsCategory({
    container: "new-case-page-container",
    explanation: "new-case-explanation",
    startTestButton: "start-test-button",
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
    goodJobText: optionalElement("good-job-text"),
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
  algorithmDrillerExplanationPage: buildElementsCategory({
    container: "algorithm-driller-explanation-page-container",
    explanation: "algorithm-driller-explanation",
    correctText: optionalElement("correct-text"),
    wrongText: optionalElement("wrong-text"),
    caseToDrill: cubeElement("case-to-drill"),
    algorithmToDrill: "algorithm-to-drill",
    continueButton: "continue-button",
  }),
  algorithmDrillerStatusPage: buildElementsCategory({
    container: "algorithm-driller-status-page-container",
    correctConsecutiveAttemptsLeft: "correct-consecutive-attempts-left",
    expectedCubeStateFront: cubeElement("expected-cube-state-front"),
    expectedCubeStateBack: cubeElement("expected-cube-state-back"),
    nextTestButton: "next-test-button",
  }),
  algorithmDrillerSuccessPage: buildElementsCategory({
    container: "algorithm-driller-success-page-container",
    explanation: "driller-success-explanation",
    nextTestButton: "next-test-button",
  }),
  globals: buildGlobalsCategory({
    anyErrorMessage: anyErrorMessage(),
    feedbackButton: "feedback-button",
  }),
};

export const getReadyWaitTime = 2400;
export const evaluateResultIgnoreTransitionsWaitTime = 300;

export const pllTrainerStatesUserDone = buildStates<
  | "startPage"
  | "pickTargetParametersPage"
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
    localStorage: fullyPopulatedLocalStorage,
    defaultNavigateOptions: {},
  },
  {
    startPage: {
      name: "startPage",
      getToThatState: (_, options) => {
        if (options?.navigateOptions?.case !== undefined)
          cy.overrideNextTestCase(options.navigateOptions.case);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.recurringUserStartPage.container.waitFor(options);
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    pickTargetParametersPage: {
      name: "pickTargetParametersPage",
      getToThatState: (getState, options) => {
        getState("startPage");
        pllTrainerElements.recurringUserStartPage.editTargetParametersButton
          .get(options)
          .click();
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.pickTargetParametersPage.container.waitFor(options);
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
        cy.clock();
        cy.pressKey(Key.space, options);
        pllTrainerElements.evaluateResult.container.waitFor(options);
        cy.tick(evaluateResultIgnoreTransitionsWaitTime, options);
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
  | "newCasePage"
  | "getReadyState"
  | "testRunning"
  | "evaluateResult"
  | "evaluateResultAfterIgnoringTransitions"
  | "algorithmDrillerExplanationPage"
  | "algorithmDrillerStatusPage"
  | "algorithmDrillerSuccessPage"
  | "pickAlgorithmPageAfterCorrect"
  | "pickAlgorithmPageAfterUnrecoverable"
  | "correctPage"
  | "typeOfWrongPage",
  // Just highlighting the separation of these two type arguments
  {
    targetParametersPicked?: boolean;
    isNewCase?: boolean;
  } & (
    | {
        case: readonly [AUF, PLL, AUF];
        algorithm: string;
      }
    | { __placeholderForTypeSafety?: unknown }
  )
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
      getToThatState: (getState, options) => {
        if (options?.navigateOptions?.targetParametersPicked) {
          // Don't do anything as we should already be here when parameters are picked
        } else {
          getState("pickTargetParametersPage");
          pllTrainerElements.pickTargetParametersPage.submitButton
            .get(options)
            .click();
        }
        if (
          options?.navigateOptions &&
          "case" in options.navigateOptions &&
          options.navigateOptions.case !== undefined
        )
          cy.overrideNextTestCase(options.navigateOptions.case);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.newUserStartPage.container
          .get(options)
          .scrollTo("top");
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    newCasePage: {
      name: "newCasePage",
      getToThatState: (getState, options) => {
        getState("startPage");
        pllTrainerElements.newUserStartPage.startButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.newCasePage.container.waitFor(options);
      },
    },
    getReadyState: {
      name: "getReadyState",
      getToThatState: (getState, options) => {
        if (options?.navigateOptions?.isNewCase ?? true) {
          getState("newCasePage");
          pllTrainerElements.newCasePage.startTestButton.get().click();
        } else {
          getState("startPage");
          pllTrainerElements.newUserStartPage.startButton
            .get(options)
            .click(options);
        }
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.getReadyState.container.waitFor(options);
      },
    },
    testRunning: {
      name: "testRunning",
      getToThatState: (getState, options) => {
        // We need to have time mocked before entering the get
        // ready page in order to programatically pass through it
        if (options?.navigateOptions?.isNewCase ?? true) {
          getState("newCasePage");
          cy.clock();
          pllTrainerElements.newCasePage.startTestButton.get().click();
        } else {
          getState("startPage");
          cy.clock();
          pllTrainerElements.newUserStartPage.startButton
            .get(options)
            .click(options);
        }
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
        // We need to go all the way back here to be able to control the time
        // the test takes, and we can only control that if we have time mocked
        // from before the test starts, not by restoring a running test, as that
        // has failed things by for example triggering the algorithm driller in the past
        if (options?.navigateOptions?.isNewCase ?? true) {
          getState("newCasePage");
          cy.clock();
          pllTrainerElements.newCasePage.startTestButton.get().click();
        } else {
          getState("startPage");
          cy.clock();
          pllTrainerElements.newUserStartPage.startButton
            .get(options)
            .click(options);
        }
        pllTrainerElements.getReadyState.container.waitFor(options);
        cy.tick(getReadyWaitTime, options);
        pllTrainerElements.testRunning.container.waitFor();
        cy.tick(evaluateResultIgnoreTransitionsWaitTime);
        cy.pressKey(Key.space, options);
        cy.clock().then((clock) => clock.restore());
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.evaluateResult.container.waitFor(options);
      },
    },
    evaluateResultAfterIgnoringTransitions: {
      name: "evaluateResultAfterIgnoringTransitions",
      getToThatState: (getState, options) => {
        // We need to go all the way back here to be able to control the time
        // the test takes, and we can only control that if we have time mocked
        // from before the test starts, not by restoring a running test, as that
        // has failed things by for example triggering the algorithm driller in the past
        if (options?.navigateOptions?.isNewCase ?? true) {
          getState("newCasePage");
          cy.clock();
          pllTrainerElements.newCasePage.startTestButton.get().click();
        } else {
          getState("startPage");
          cy.clock();
          pllTrainerElements.newUserStartPage.startButton
            .get(options)
            .click(options);
        }
        pllTrainerElements.getReadyState.container.waitFor(options);
        cy.tick(getReadyWaitTime, options);
        pllTrainerElements.testRunning.container.waitFor();
        cy.tick(evaluateResultIgnoreTransitionsWaitTime);
        cy.pressKey(Key.space, options);
        pllTrainerElements.evaluateResult.container.waitFor(options);
        cy.tick(evaluateResultIgnoreTransitionsWaitTime, options);
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
        const { case: caseToSet, algorithm } =
          options?.navigateOptions &&
          "case" in options.navigateOptions &&
          options.navigateOptions.case !== undefined
            ? options.navigateOptions
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
    algorithmDrillerExplanationPage: {
      name: "algorithmDrillerExplanationPage",
      getToThatState: (getState, options) => {
        getState("pickAlgorithmPageAfterUnrecoverable");
        const { case: caseToSet, algorithm } =
          options?.navigateOptions &&
          "case" in options.navigateOptions &&
          options.navigateOptions.case !== undefined
            ? options.navigateOptions
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
      waitForStateToAppear: (options) => {
        pllTrainerElements.algorithmDrillerExplanationPage.container.waitFor(
          options
        );
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    algorithmDrillerStatusPage: {
      name: "algorithmDrillerStatusPage",
      getToThatState: (getState, options) => {
        getState("algorithmDrillerExplanationPage");
        pllTrainerElements.algorithmDrillerExplanationPage.continueButton
          .get(options)
          .click(options);
      },
      waitForStateToAppear: (options) => {
        pllTrainerElements.algorithmDrillerStatusPage.container.waitFor(
          options
        );
        cy.waitForDocumentEventListeners("keyup");
      },
    },
    algorithmDrillerSuccessPage: {
      name: "algorithmDrillerSuccessPage",
      getToThatState: (getState, options) => {
        getState("algorithmDrillerStatusPage");
        cy.clock();
        for (let i = 0; i < 3; i++) {
          pllTrainerElements.algorithmDrillerStatusPage.nextTestButton
            .get(options)
            .click(options);
          fromGetReadyForTestThroughEvaluateResult({
            cyClockAlreadyCalled: true,
            resultType: "correct",
            milliseconds: 500,
          });
        }
      },
      waitForStateToAppear: (options?: StateOptions) => {
        pllTrainerElements.algorithmDrillerSuccessPage.container.waitFor(
          options
        );
        cy.waitForDocumentEventListeners("keyup");
      },
    },
  } as const
);

export function completePLLTestInMilliseconds(
  milliseconds: number,
  params: {
    startingState:
      | "doNewVisit"
      | "pickTargetParametersPage"
      | "startPage"
      | "correctPage";
    forceTestCase?: readonly [AUF, PLL, AUF];
    // The function will not throw an error if it can't reach this state
    // it's just simple decisions like ending early or continuing a bit further
    // that this parameter is for.
    endingState?:
      | "testRunning"
      | "correctPage"
      | "wrongPage"
      | "algorithmDrillerExplanationPage"
      | "algorithmDrillerStatusPage";
    overrideDefaultAlgorithm?: string;
    startPageCallback?: () => void;
    newCasePageCallback?: () => void;
    testRunningCallback?: () => void;
    evaluateResultCallback?: () => void;
  } & (
    | {
        correct: true;
        correctPageCallback?: () => void;
        algorithmDrillerExplanationPageCallback?: () => void;
        algorithmDrillerStatusPageCallback?: () => void;
      }
    | ({ correct: false } & (
        | {
            wrongPageCallback?: () => void;
            algorithmDrillerExplanationPageCallback?: never;
            algorithmDrillerStatusPageCallback?: never;
          }
        | {
            wrongPageCallback?: never;
            algorithmDrillerExplanationPageCallback?: () => void;
            algorithmDrillerStatusPageCallback?: () => void;
          }
      ))
  )
): void {
  cy.wrap(null, { log: false }).then(function (this: Cypress.CypressThis) {
    if (this.clock) {
      throw new Error(
        "Don't call completePLLTestInMilliseconds with time mocked, time mocking should be reduced to a minimum, as it interferes with Elm commands"
      );
    }
  });
  const {
    forceTestCase,
    correct,
    overrideDefaultAlgorithm,
    startingState,
    endingState,
    startPageCallback,
    newCasePageCallback,
    testRunningCallback,
    evaluateResultCallback,
  } = params;
  const { stateAttributeValues } = pllTrainerElements.root;

  let atStartPage = true;

  if (startingState === "doNewVisit") {
    let loaded = false;
    cy.visit(paths.pllTrainer, { onLoad: () => (loaded = true) });
    cy.waitUntil(() => loaded);
    pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
      if (
        stateValue ===
        pllTrainerElements.root.stateAttributeValues.pickTargetParametersPage
      ) {
        pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
      }
    });
  } else if (startingState === "pickTargetParametersPage") {
    pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
  } else if (startingState !== "startPage") {
    atStartPage = false;
  }

  if (startingState === "startPage") {
    // In case someone for some reason calls this right after calling cy.visit with
    // startPage starting state instead of just using "doNewVisit" starting state.
    // Because that could cause issues with calling the meta functions below before
    // waiting for the page to load
    pllTrainerElements.newUserStartPage.container.waitFor();
  }
  if (forceTestCase) cy.overrideNextTestCase(forceTestCase);
  cy.clock();

  if (atStartPage) {
    pllTrainerElements.newUserStartPage.container.waitFor();
    startPageCallback?.();
    pllTrainerElements.newUserStartPage.startButton.get().click();
    pllTrainerElements.root.waitForStateChangeAwayFrom(
      stateAttributeValues.startPage
    );
  } else if (startingState === "correctPage") {
    pllTrainerElements.correctPage.nextButton.get().click();
  }

  pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
    // It is purposeful this is here before we know if new case page is actually
    // displaying, as we want to allow for assert doesn't exist in the callback
    // and also for it to error if you try finding new case page in a case where
    // it doesn't display
    newCasePageCallback?.();
    if (stateValue === stateAttributeValues.newCasePage) {
      pllTrainerElements.newCasePage.startTestButton.get().click();
    }
  });
  fromGetReadyForTestThroughEvaluateResult({
    cyClockAlreadyCalled: true,
    keepClockOn: false,
    milliseconds,
    resultType: correct ? "correct" : "unrecoverable",
    endingState: endingState === "testRunning" ? "testRunning" : undefined,
    ...(testRunningCallback === undefined ? {} : { testRunningCallback }),
    ...(evaluateResultCallback === undefined ? {} : { evaluateResultCallback }),
  });
  pllTrainerElements.root
    .getStateAttributeValue()
    .then(
      (stateValue): Cypress.Chainable<{ pll: PLL | null }> => {
        if (stateValue === stateAttributeValues.pickAlgorithmPage) {
          if (forceTestCase)
            return cy.wrap({ pll: forceTestCase[1] } as { pll: PLL | null });
          return cy
            .getCurrentTestCase()
            .then(([, pll]) => ({ pll } as { pll: PLL | null }));
        }
        return cy.wrap({ pll: null } as { pll: PLL | null });
      }
    )
    .then(({ pll: pllIfOnPickAlgorithmPage }) => {
      if (pllIfOnPickAlgorithmPage !== null) {
        const pll = pllIfOnPickAlgorithmPage;
        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type(
            (overrideDefaultAlgorithm ?? pllToAlgorithmString[pll]) + "{enter}"
          );
      }
    });
  if (correct && params.correctPageCallback) {
    pllTrainerElements.correctPage.container.waitFor();
    params.correctPageCallback();
  } else if (!correct && params.wrongPageCallback) {
    pllTrainerElements.wrongPage.container.waitFor();
    params.wrongPageCallback();
  }
  if (params.algorithmDrillerExplanationPageCallback) {
    pllTrainerElements.algorithmDrillerExplanationPage.container.waitFor();
    params.algorithmDrillerExplanationPageCallback?.();
  }
  if (
    params.algorithmDrillerStatusPageCallback ||
    endingState === "algorithmDrillerStatusPage"
  ) {
    pllTrainerElements.algorithmDrillerExplanationPage.continueButton
      .get()
      .click();
    pllTrainerElements.algorithmDrillerStatusPage.container.waitFor();
    params.algorithmDrillerStatusPageCallback?.();
  }
}

export function fromGetReadyForTestThroughEvaluateResult(
  params: {
    // This is just for communication about requirements to caller
    cyClockAlreadyCalled: true;
    keepClockOn: boolean;
    milliseconds: number;
    endingState?: "testRunning" | undefined;
    testRunningCallback?: () => void;
    evaluateResultCallback?: () => void;
    testRunningNavigator?: () => void;
  } & (
    | {
        resultType: "correct";
        evaluateResultCorrectNavigator?: () => void;
      }
    | {
        resultType: "unrecoverable" | "nearly there" | "no moves made";
        evaluateResultWrongNavigator?: () => void;
      }
  )
): void {
  const {
    milliseconds,
    testRunningCallback,
    evaluateResultCallback,
    testRunningNavigator,
    resultType,
    keepClockOn,
    endingState,
  } = params;
  const { stateAttributeValues } = pllTrainerElements.root;

  pllTrainerElements.getReadyState.container.waitFor();
  cy.tick(getReadyWaitTime);
  pllTrainerElements.testRunning.container.waitFor();
  cy.tick(milliseconds);
  testRunningCallback?.();
  if (endingState === "testRunning") {
    if (!keepClockOn) cy.clock().invoke("restore");
    return;
  }
  (testRunningNavigator ?? (() => cy.mouseClickScreen("center")))();
  pllTrainerElements.evaluateResult.container.waitFor();
  cy.tick(evaluateResultIgnoreTransitionsWaitTime);
  if (!keepClockOn) cy.clock().invoke("restore");
  evaluateResultCallback?.();
  if (resultType === "correct") {
    (
      params.evaluateResultCorrectNavigator ??
      (() => pllTrainerElements.evaluateResult.correctButton.get().click())
    )();
    pllTrainerElements.root.waitForStateChangeAwayFrom(
      stateAttributeValues.evaluateResultPage
    );
  } else {
    (
      params.evaluateResultWrongNavigator ??
      (() => pllTrainerElements.evaluateResult.wrongButton.get().click())
    )();
    if (resultType === "unrecoverable") {
      pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
    } else if (resultType === "nearly there") {
      pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
    } else {
      pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
    }
    pllTrainerElements.root.waitForStateChangeAwayFrom(
      stateAttributeValues.typeOfWrongPage
    );
  }
}
