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
  | "typeOfWrongPage"
  | "wrongPage",
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
        for (let i = 0; i < 3; i++) {
          fromGetReadyForTestThroughEvaluateResult({
            correct: true,
            milliseconds: 500,
            navigateToGetReadyState: () =>
              pllTrainerElements.algorithmDrillerStatusPage.nextTestButton
                .get(options)
                .click(options),
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
    wrongPage: {
      name: "wrongPage",
      getToThatState: () => {},
      waitForStateToAppear(options) {
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
    aufs: readonly [AUF, AUF] | readonly [];
    overrideDefaultAlgorithm?: string;
    startPageCallback?: () => void;
    newCasePageCallback?: () => void;
    testRunningCallback?: () => void;
  } & ({ correct: true } | { correct: false; wrongPageCallback?: () => void })
): void {
  const {
    aufs,
    correct,
    overrideDefaultAlgorithm,
    startPageCallback,
    newCasePageCallback,
    testRunningCallback,
  } = params;
  const [preAUF, postAUF] = [aufs[0] ?? AUF.none, aufs[1] ?? AUF.none];
  const testCase = [preAUF, pll, postAUF] as const;
  const { stateAttributeValues } = pllTrainerElements.root;

  cy.visit(paths.pllTrainer);
  pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
    if (stateValue === stateAttributeValues.pickTargetParametersPage) {
      pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
    }
  });

  pllTrainerElements.newUserStartPage.container.waitFor();
  startPageCallback?.();
  cy.overrideNextTestCase(testCase);
  fromGetReadyForTestThroughEvaluateResult({
    correct,
    milliseconds,
    navigateToGetReadyState: () => {
      pllTrainerElements.newUserStartPage.startButton.get().click();
      pllTrainerElements.root.waitForStateChangeAwayFrom(
        stateAttributeValues.startPage
      );

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
    },
    ...(testRunningCallback === undefined ? {} : { testRunningCallback }),
  });
  pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
    if (stateValue === stateAttributeValues.pickAlgorithmPage) {
      pllTrainerElements.pickAlgorithmPage.algorithmInput
        .get()
        .type(
          (overrideDefaultAlgorithm ?? pllToAlgorithmString[pll]) + "{enter}"
        );
    }
  });
  if (correct) pllTrainerElements.correctPage.container.waitFor();
  else {
    pllTrainerElements.wrongPage.container.waitFor();
    params.wrongPageCallback?.();
  }
}

export function fromGetReadyForTestThroughEvaluateResult({
  milliseconds,
  correct,
  navigateToGetReadyState,
  testRunningCallback,
}: {
  milliseconds: number;
  correct: boolean;
  navigateToGetReadyState: () => void;
  testRunningCallback?: () => void;
}): void {
  const { stateAttributeValues } = pllTrainerElements.root;

  cy.clock();
  navigateToGetReadyState();

  pllTrainerElements.getReadyState.container.waitFor();
  cy.tick(getReadyWaitTime);
  pllTrainerElements.testRunning.container.waitFor();
  cy.tick(milliseconds);
  testRunningCallback?.();
  cy.pressKey(Key.space);
  pllTrainerElements.evaluateResult.container.waitFor();
  cy.tick(500);
  cy.clock().then((clock) => clock.restore());
  if (correct) {
    pllTrainerElements.evaluateResult.correctButton.get().click();
    pllTrainerElements.root.waitForStateChangeAwayFrom(
      stateAttributeValues.evaluateResultPage
    );
  } else {
    pllTrainerElements.evaluateResult.wrongButton.get().click();
    pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
    pllTrainerElements.root.waitForStateChangeAwayFrom(
      stateAttributeValues.typeOfWrongPage
    );
  }
}
