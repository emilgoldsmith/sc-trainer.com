import {
  buildElementsCategory,
  buildGlobalsCategory,
  cubeElement,
  anyErrorMessage,
  errorMessageElement,
  optionalElement,
  buildRootCategory,
} from "support/elements";
import { paths } from "support/paths";
import { AUF, PLL, pllToAlgorithmString } from "support/pll";

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

export function completePLLTestInMilliseconds(
  milliseconds: number,
  params: {
    startingState:
      | "doNewVisit"
      | "pickTargetParametersPage"
      | "startPage"
      | "newCasePage"
      | "algorithmDrillerStatusPage"
      | "algorithmDrillerSuccessPage"
      | "correctPage"
      | "wrongPage";
    forceTestCase?: readonly [AUF, PLL, AUF];
    // The function will not throw an error if it can't reach this state
    // it's just simple decisions like ending early or continuing a bit further
    // that this parameter is for.
    endingState?:
      | "testRunning"
      | "pickAlgorithmPage"
      | "correctPage"
      | "typeOfWrongPage"
      | "wrongPage"
      | "algorithmDrillerExplanationPage"
      | "algorithmDrillerStatusPage"
      | "algorithmDrillerSuccessPage"
      | undefined;
    overrideDefaultAlgorithm?: string;
    pickTargetParametersNavigator?: () => void;
    startPageCallback?: () => void;
    newCasePageCallback?: () => void;
    assertNewCasePageDidntDisplay?: boolean;
    newCasePageNavigator?: () => void;
    getReadyCallback?: () => void;
    beginningOfTestRunningCallback?: () => void;
    testRunningCallback?: () => void;
    testRunningNavigator?: () => void;
    evaluateResultCallback?: () => void;
    correctPageNavigator?: () => void;
    wrongPageNavigator?: () => void;
    algorithmDrillerStatusPageNavigator?: () => void;
  } & (
    | {
        correct: true;
        evaluateResultCorrectNavigator?: () => void;
        correctPageCallback?: () => void;
        algorithmDrillerExplanationPageCallback?: () => void;
        algorithmDrillerStatusPageCallback?: () => void;
      }
    | ({
        correct: false;
        wrongType: "unrecoverable" | "nearly there" | "no moves made";
        evaluateResultWrongNavigator?: () => void;
      } & (
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
  cy.withOverallNameLogged(
    {
      message: `completePLLTestInMilliseconds, milliseconds: ${milliseconds.toString()}, params: ${JSON.stringify(
        params
      )}`,
    },
    () => {
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
        pickTargetParametersNavigator,
        startPageCallback,
        newCasePageCallback,
        assertNewCasePageDidntDisplay,
        newCasePageNavigator,
        getReadyCallback,
        beginningOfTestRunningCallback,
        testRunningCallback,
        testRunningNavigator,
        evaluateResultCallback,
        correctPageNavigator,
        wrongPageNavigator,
        algorithmDrillerStatusPageNavigator,
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
            pllTrainerElements.root.stateAttributeValues
              .pickTargetParametersPage
          ) {
            (
              pickTargetParametersNavigator ??
              (() =>
                pllTrainerElements.pickTargetParametersPage.submitButton
                  .get()
                  .click())
            )();
          }
        });
      } else if (startingState === "pickTargetParametersPage") {
        (
          pickTargetParametersNavigator ??
          (() =>
            pllTrainerElements.pickTargetParametersPage.submitButton
              .get()
              .click())
        )();
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
        (
          correctPageNavigator ??
          (() => pllTrainerElements.correctPage.nextButton.get().click())
        )();
      } else if (startingState === "wrongPage") {
        (
          wrongPageNavigator ??
          (() => pllTrainerElements.wrongPage.nextButton.get().click())
        )();
      } else if (startingState === "algorithmDrillerStatusPage") {
        (
          algorithmDrillerStatusPageNavigator ??
          (() =>
            pllTrainerElements.algorithmDrillerStatusPage.nextTestButton
              .get()
              .click())
        )();
      } else if (startingState === "algorithmDrillerSuccessPage") {
        pllTrainerElements.algorithmDrillerSuccessPage.nextTestButton
          .get()
          .click();
      }

      pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
        if (stateValue === stateAttributeValues.newCasePage) {
          if (assertNewCasePageDidntDisplay) {
            throw new Error(
              "New case page displayed despite assertion that it shouldn't"
            );
          }
          newCasePageCallback?.();
          (
            newCasePageNavigator ??
            (() => pllTrainerElements.newCasePage.startTestButton.get().click())
          )();
        } else if (newCasePageCallback) {
          throw new Error(
            "newCasePageCallback was provided but there was no new case page"
          );
        }
      });

      pllTrainerElements.getReadyState.container.waitFor();
      getReadyCallback?.();
      cy.tick(getReadyWaitTime);
      pllTrainerElements.testRunning.container.waitFor();
      beginningOfTestRunningCallback?.();
      cy.tick(milliseconds);
      testRunningCallback?.();
      if (endingState === "testRunning") {
        cy.clock().invoke("restore");
        return;
      }
      (testRunningNavigator ?? (() => cy.mouseClickScreen("center")))();
      pllTrainerElements.evaluateResult.container.waitFor();
      cy.tick(evaluateResultIgnoreTransitionsWaitTime);
      cy.clock().invoke("restore");
      evaluateResultCallback?.();
      if (correct) {
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
        if (endingState === "typeOfWrongPage") return;
        if (params.wrongType === "unrecoverable") {
          pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
        } else if (params.wrongType === "nearly there") {
          pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
        } else {
          pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
        }
        pllTrainerElements.root.waitForStateChangeAwayFrom(
          stateAttributeValues.typeOfWrongPage
        );
      }

      if (endingState === "pickAlgorithmPage") return;
      pllTrainerElements.root
        .getStateAttributeValue()
        .then(
          (stateValue): Cypress.Chainable<{ pll: PLL | null }> => {
            if (stateValue === stateAttributeValues.pickAlgorithmPage) {
              if (forceTestCase)
                return cy.wrap({ pll: forceTestCase[1] } as {
                  pll: PLL | null;
                });
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
                (overrideDefaultAlgorithm ?? pllToAlgorithmString[pll]) +
                  "{enter}"
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
        pllTrainerElements.root.getStateAttributeValue().then((stateValue) => {
          if (
            stateValue === stateAttributeValues.algorithmDrillerExplanationPage
          ) {
            pllTrainerElements.algorithmDrillerExplanationPage.continueButton
              .get()
              .click();
          }
        });
        pllTrainerElements.algorithmDrillerStatusPage.container.waitFor();
        params.algorithmDrillerStatusPageCallback?.();
      }
    }
  );
}
