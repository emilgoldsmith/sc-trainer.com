import { assertCubeMatchesStateString } from "support/assertions";
import { OurElement } from "support/elements";
import { applyDefaultIntercepts } from "support/interceptors";
import { getKeyValue, Key } from "support/keys";
import { paths } from "support/paths";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";
import {
  AUF,
  aufToAlgorithmString,
  PLL,
  pllToAlgorithmString,
  pllToPllLetters,
} from "support/pll";
import {
  evaluateResultIgnoreTransitionsWaitTime,
  fromGetReadyForTestThroughEvaluateResult,
  getReadyWaitTime,
  pllTrainerElements,
} from "./pll-trainer/state-and-elements";

type Aliases = {
  solvedFront: string;
  solvedBack: string;
  testCaseFront: string;
  testCaseBack: string;
  evaluateResultFront: string;
  evaluateResultBack: string;
  previousEvaluateResultFront: string;
  previousEvaluateResultBack: string;
};

describe("PLL Trainer", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
  });

  it("recurring user", function () {
    cy.setLocalStorage(fullyPopulatedLocalStorage);
    cy.visit(paths.pllTrainer);
    cy.withOverallNameLogged(
      { message: "Done User Start Page" },
      recurringUserStartPageNoSideEffectsButScroll
    );
  });

  it("todo", function () {
    cy.visit(paths.pllTrainer);
    pllTrainerElements.pickTargetParametersPage.container.waitFor();
    const testCaseOrder: [AUF, PLL, AUF][] = [
      [AUF.U, PLL.Aa, AUF.none],
      [AUF.U2, PLL.Ab, AUF.UPrime],
      [AUF.U2, PLL.E, AUF.U2],
      [AUF.UPrime, PLL.Ga, AUF.U],
      [AUF.none, PLL.Gb, AUF.none],
    ];
    let testCaseIndex = 0;
    function getCurrentTestCase() {
      const nextCase = testCaseOrder[testCaseIndex];
      if (nextCase === undefined)
        throw new Error(
          "test case index out of bounds: " + testCaseIndex.toString()
        );
      return nextCase;
    }
    function getNextTestCase() {
      const nextCase = testCaseOrder[testCaseIndex + 1];
      if (nextCase === undefined)
        throw new Error(
          "test case index out of bounds: " + testCaseIndex.toString()
        );
      return nextCase;
    }
    cy.overrideNextTestCase(getCurrentTestCase());
    cy.withOverallNameLogged(
      { message: "Pick Target Parameters No Side Effects" },
      pickTargetParametersPageNoSideEffectsButScroll
    );
    cy.withOverallNameLogged(
      { message: "Pick Target Parameters Side Effects" },
      pickTargetParametersPageSideEffectsExceptNavigations
    );
    cy.withOverallNameLogged({ message: "To New User Page" }, () => {
      pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
        .get()
        .type("{selectall}{backspace}2");
      pllTrainerElements.pickTargetParametersPage.targetTPSInput
        .get()
        .type("{selectall}{backspace}4");
      pickTargetParametersNavigateVariant1();
    });
    pllTrainerElements.newUserStartPage.container.get().scrollTo("topLeft");
    cy.withOverallNameLogged(
      {
        message: "New User Start Page",
      },
      newUserStartPageNoSideEffectsButScroll
    );
    pllTrainerElements.newUserStartPage.cubeStartState
      .getStringRepresentationOfCube()
      .setAlias<Aliases, "solvedFront">("solvedFront");
    cy.overrideCubeDisplayAngle("ubl");
    pllTrainerElements.newUserStartPage.cubeStartState
      .getStringRepresentationOfCube()
      .setAlias<Aliases, "solvedBack">("solvedBack");
    cy.overrideCubeDisplayAngle(null);
    cy.withOverallNameLogged(
      { message: "To New Case Page" },
      newUserStartPageBeginNavigateVariant1
    );
    cy.withOverallNameLogged(
      { message: "New Case Page" },
      newCasePageNoSideEffectsButScroll
    );
    cy.clock();
    cy.withOverallNameLogged(
      { message: "To Get Ready State" },
      newCasePageNavigateVariant1
    );
    cy.withOverallNameLogged(
      { message: "Get Ready State" },
      getReadyStateNoSideEffectsButScroll
    );
    cy.tick(getReadyWaitTime);
    cy.withOverallNameLogged(
      { message: "Test Running" },
      testRunningNoSideEffectsButScroll
    );
    cy.withOverallNameLogged(
      { message: "To Evaluate Result" },
      testRunningNavigateVariant1
    );
    cy.withOverallNameLogged(
      { message: "Evaluate Result Page While Ignoring Transitions" },
      evaluateResultWhileIgnoringTransitionsNoSideEffects
    );
    cy.tick(evaluateResultIgnoreTransitionsWaitTime);
    cy.withOverallNameLogged(
      { message: "Evaluate Result Page After Ignoring Transitions" },
      evaluateResultAfterIgnoringTransitionsNoSideEffects
    );
    pllTrainerElements.evaluateResult.expectedCubeFront
      .getStringRepresentationOfCube()
      .setAlias<Aliases, "previousEvaluateResultFront">(
        "previousEvaluateResultFront"
      );
    pllTrainerElements.evaluateResult.expectedCubeBack
      .getStringRepresentationOfCube()
      .setAlias<Aliases, "previousEvaluateResultBack">(
        "previousEvaluateResultBack"
      );
    cy.withOverallNameLogged(
      { message: "To Pick Algorithm Page" },
      evaluateResultNavigateCorrectVariant1
    );
    cy.withOverallNameLogged({ message: "Pick Algorithm Page" }, () => {
      function changePLL() {
        testCaseIndex++;
        cy.setCurrentTestCase(getCurrentTestCase());
      }
      pickAlgorithmPageFirstThingNoSideEffects();
      pickAlgorithmPageSideEffectsExceptNavigations(
        getCurrentTestCase()[1],
        changePLL,
        getNextTestCase()[1]
      );
    });
    cy.withOverallNameLogged({ message: "To Correct Page" }, () => {
      pickAlgorithmNavigateVariant1(getCurrentTestCase()[1]);
    });
    cy.withOverallNameLogged({ message: "Correct Page" }, () => {
      correctPageNoSideEffects();
    });
    cy.withOverallNameLogged({ message: "To Type Of Wrong Page" }, () => {
      cy.overrideNextTestCase(getNextTestCase());
      correctPageNavigateVariant1();
      pllTrainerElements.newCasePage.container.waitFor();
      newCasePageNavigateVariant2();
      pllTrainerElements.getReadyState.container.waitFor();
      cy.tick(getReadyWaitTime);
      pllTrainerElements.testRunning.container.waitFor();
      testCaseIndex++;
      pllTrainerElements.testRunning.testCase
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "testCaseFront">("testCaseFront");
      testRunningNavigateVariant2();
      cy.tick(evaluateResultIgnoreTransitionsWaitTime);
      pllTrainerElements.evaluateResult.expectedCubeFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "evaluateResultFront">("evaluateResultFront");
      pllTrainerElements.evaluateResult.expectedCubeBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "evaluateResultBack">("evaluateResultBack");
      evaluateResultNavigateWrongVariant1();
    });
    cy.withOverallNameLogged({ message: "Type Of Wrong Page" }, () => {
      cy.getAliases<Aliases>()
        .then((aliases) =>
          verifyKeysDefined(aliases, [
            "previousEvaluateResultFront",
            "previousEvaluateResultBack",
            "evaluateResultFront",
            "evaluateResultBack",
          ])
        )
        .then(
          ({
            previousEvaluateResultFront,
            previousEvaluateResultBack,
            evaluateResultFront,
            evaluateResultBack,
          }) =>
            TypeOfWrongPageNoSideEffects({
              originalExpectedCubeFront: previousEvaluateResultFront,
              originalExpectedCubeBack: previousEvaluateResultBack,
              nextExpectedCubeFront: evaluateResultFront,
              nextExpectedCubeBack: evaluateResultBack,
            })
        );
    });
    cy.withOverallNameLogged(
      { message: "To Algorithm Driller Explanation Page" },
      () => {
        typeOfWrongPageNoMovesNavigateVariant1();
        pickAlgorithmNavigateVariant2(getCurrentTestCase()[1]);
      }
    );
    cy.withOverallNameLogged(
      { message: "Algorithm Driller Explanation Page" },
      () => {
        cy.getAliases<Aliases>()
          .then((aliases) => verifyKeysDefined(aliases, ["testCaseFront"]))
          .then(({ testCaseFront }) =>
            algorithmDrillerExplanationPageNoSideEffectsButScroll({
              testCaseCube: testCaseFront,
            })
          );
      }
    );
    cy.withOverallNameLogged(
      { message: "To Algorithm Driller Status Page" },
      () => {
        algorithmDrillerExplanationPageNavigateVariant1();
      }
    );
    cy.withOverallNameLogged(
      { message: "Algorithm Driller Status Page" },
      () => {
        cy.getAliases<Aliases>()
          .then((aliases) =>
            verifyKeysDefined(aliases, ["solvedFront", "solvedBack"])
          )
          .then((aliases) =>
            algorithmDrillerStatusPageNoSideEffects({
              expectedCubeStateWasNotSolvedBeforeThis: true,
              ...aliases,
            })
          );
      }
    );
    cy.withOverallNameLogged(
      {
        message:
          "Complete Three Drills Successfully, ending at Algorithm Driller Success Page",
      },
      () => {
        algorithmDrillerStatusPageNavigateVariant1();
        fromGetReadyForTestThroughEvaluateResult({
          cyClockAlreadyCalled: true,
          milliseconds: 500,
          correct: true,
          testRunningNavigator: testRunningNavigateVariant3,
          evaluateResultCallback() {
            pllTrainerElements.evaluateResult.expectedCubeFront
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultFront">("evaluateResultFront");
            pllTrainerElements.evaluateResult.expectedCubeBack
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultBack">("evaluateResultBack");
          },
          evaluateResultCorrectNavigator: evaluateResultNavigateCorrectVariant2,
        });
        cy.withOverallNameLogged({ message: "After 1 success" }, () => {
          cy.getAliases<Aliases>()
            .then((aliases) =>
              verifyKeysDefined(aliases, [
                "evaluateResultFront",
                "evaluateResultBack",
              ])
            )
            .then(algorithmDrillerStatusPageAfter1SuccessNoSideEffects);
        });
        algorithmDrillerStatusPageNavigateVariant2();
        fromGetReadyForTestThroughEvaluateResult({
          cyClockAlreadyCalled: true,
          milliseconds: 500,
          correct: true,
          testRunningNavigator: testRunningNavigateVariant4,
          evaluateResultCorrectNavigator: evaluateResultNavigateCorrectVariant1,
        });
        cy.withOverallNameLogged(
          { message: "After 2 successes" },
          algorithmDrillerStatusPageAfter2SuccessesNoSideEffects
        );
        algorithmDrillerStatusPageNavigateVariant1();
        fromGetReadyForTestThroughEvaluateResult({
          cyClockAlreadyCalled: true,
          milliseconds: 500,
          correct: true,
          testRunningNavigator: testRunningNavigateVariant5,
          evaluateResultCorrectNavigator: evaluateResultNavigateCorrectVariant1,
        });
      }
    );
    cy.withOverallNameLogged(
      { message: "Algorithm Driller Success Page" },
      () => {
        algorithmDrillerSuccessPageNoSideEffects();
      }
    );
    cy.withOverallNameLogged({ message: "To Wrong Page" }, () => {
      // Redo the same case so we don't go over the driller stuff etc.
      cy.overrideNextTestCase(getCurrentTestCase());
      algorithmDrillerSuccessPageNavigateVariant1();
      fromGetReadyForTestThroughEvaluateResult({
        cyClockAlreadyCalled: true,
        milliseconds: 100,
        wrong: "nearly there",
        testRunningCallback() {
          cy.overrideDisplayCubeAnnotations(true);
          pllTrainerElements.testRunning.testCase
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "testCaseFront">("testCaseFront");
          cy.overrideCubeDisplayAngle("ubl");
          pllTrainerElements.testRunning.testCase
            .getStringRepresentationOfCube()
            .setAlias<Aliases, "testCaseBack">("testCaseBack");
          cy.overrideCubeDisplayAngle(null);
          cy.overrideDisplayCubeAnnotations(null);
        },
      });
    });
    cy.withOverallNameLogged({ message: "Wrong Page" }, () => {
      cy.getAliases<Aliases>()
        .then((aliases) =>
          verifyKeysDefined(aliases, ["testCaseFront", "testCaseBack"])
        )
        .then((aliases) => {
          wrongPageNoSideEffects({
            nearlyThereTypeOfWrongWasUsed: true,
            currentTestCase: getCurrentTestCase(),
            ...aliases,
          });
        });
    });
  });
});

function verifyKeysDefined<Keys extends string, PickedKeys extends Keys>(
  object: Partial<Record<Keys, string | undefined>>,
  keys: PickedKeys[]
): { [key in PickedKeys]: string } {
  const result: { [key in PickedKeys]: string } = {} as {
    [key in PickedKeys]: string;
  };
  for (const key of keys) {
    const value: string | undefined = object[key];
    if (value === undefined) {
      throw new Error(`Key ${key} is not defined`);
    }
    result[key] = value;
  }
  return result;
}

function pickTargetParametersPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.pickTargetParametersPage;

  ([
    [
      "looks right",
      () => {
        elements.explanation.assertConsumableViaVerticalScroll(
          elements.container.specifier
        );
        elements.recognitionTimeInput.assertConsumableViaVerticalScroll(
          elements.container.specifier
        );
        elements.targetTPSInput.assertConsumableViaVerticalScroll(
          elements.container.specifier
        );
        elements.submitButton.assertConsumableViaVerticalScroll(
          elements.container.specifier
        );
        cy.assertNoHorizontalScrollbar();
      },
    ],
    [
      "has correct default values",
      () => {
        elements.recognitionTimeInput.get().should("have.value", "2");
        elements.targetTPSInput.get().should("have.value", "2.5");
      },
    ],
    [
      "displays decimal keyboard on mobile devices",
      () => {
        elements.recognitionTimeInput
          .get()
          .should("have.attr", "inputmode", "decimal");
        elements.targetTPSInput
          .get()
          .should("have.attr", "inputmode", "decimal");
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function pickTargetParametersPageSideEffectsExceptNavigations() {
  const elements = pllTrainerElements.pickTargetParametersPage;

  ([
    [
      "correctly inputs decimal inputs including converting commas to periods",
      () => {
        elements.recognitionTimeInput
          .get()
          .type("{selectall}{backspace}13.5", { delay: 0 })
          .should("have.value", "13.5");
        elements.targetTPSInput
          .get()
          .type("{selectall}{backspace}23.7", { delay: 0 })
          .should("have.value", "23.7");
        elements.recognitionTimeInput
          .get()
          .type("{selectall}{backspace}1,3", { delay: 0 })
          .should("have.value", "1.3");
        elements.targetTPSInput
          .get()
          .type("{selectall}{backspace}2,9", { delay: 0 })
          .should("have.value", "2.9");
      },
    ],
    [
      "displays error exactly if there's an invalid number",
      () => {
        testInput(elements.recognitionTimeInput, elements.recognitionTimeError);
        testInput(elements.targetTPSInput, elements.tpsError);

        function testInput(
          inputElement: OurElement,
          expectedError: OurElement
        ) {
          inputElement
            .get()
            .type("{selectall}{backspace}abc", { delay: 0 })
            .blur();
          expectedError.assertShows();
          inputElement
            .get()
            .type("{selectall}{backspace}3.5", { delay: 0 })
            .blur();
          expectedError.assertDoesntExist();
          inputElement
            .get()
            .type("{selectall}{backspace}3.5.5", { delay: 0 })
            .blur();
          expectedError.assertShows();
          inputElement
            .get()
            .type("{selectall}{backspace}61.1", { delay: 0 })
            .blur();
          expectedError.assertDoesntExist();
          // Empty input should also error
          inputElement
            .get()
            .type("{selectall}{backspace}", { delay: 0 })
            .blur();
          expectedError.assertShows();
        }
      },
    ],
    ...([
      {
        method: "submit button",
        submit: () => elements.submitButton.get().click(),
      },
      {
        method: "enter in recognition time input",
        submit: () => elements.recognitionTimeInput.get().type("{enter}"),
      },
      {
        method: "enter in TPS input",
        submit: () => elements.targetTPSInput.get().type("{enter}"),
      },
    ] as const).map(
      ({ method, submit }) =>
        [
          "doesn't submit if there are errors using " + method,
          () => {
            makeInvalid(
              elements.recognitionTimeInput,
              elements.recognitionTimeError
            );
            submit();
            elements.container.assertShows();
            makeInvalid(elements.targetTPSInput, elements.tpsError);
            submit();
            elements.container.assertShows();
            makeValid(
              elements.recognitionTimeInput,
              elements.recognitionTimeError
            );
            submit();
            elements.container.assertShows();

            function makeInvalid(
              inputElement: OurElement,
              errorElement: OurElement
            ) {
              inputElement.get().type("abc", { delay: 0 });
              errorElement.waitFor();
            }
            function makeValid(
              inputElement: OurElement,
              errorElement: OurElement
            ) {
              inputElement
                .get()
                .type("{selectall}{backspace}2.0", { delay: 0 });
              errorElement.assertDoesntExist();
            }
          },
        ] as const
    ),
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function pickTargetParametersNavigateVariant1() {
  pllTrainerElements.pickTargetParametersPage.submitButton.get().click();
  pllTrainerElements.pickTargetParametersPage.container.assertDoesntExist();
}

function pickTargetParametersNavigateVariant2() {
  pllTrainerElements.pickTargetParametersPage.recognitionTimeInput
    .get()
    .type("{enter}");
  pllTrainerElements.pickTargetParametersPage.container.assertDoesntExist();
}

function pickTargetParametersNavigateVariant3() {
  pllTrainerElements.pickTargetParametersPage.targetTPSInput
    .get()
    .type("{enter}");
  pllTrainerElements.pickTargetParametersPage.container.assertDoesntExist();
}

function testPickTargetParametersOnlySubmitsWithNoErrors(submit: () => void) {
  const elements = pllTrainerElements.pickTargetParametersPage;

  makeInvalid(elements.recognitionTimeInput, elements.recognitionTimeError);
  submit();
  elements.container.assertShows();
  makeInvalid(elements.targetTPSInput, elements.tpsError);
  submit();
  elements.container.assertShows();
  makeValid(elements.recognitionTimeInput, elements.recognitionTimeError);
  submit();
  elements.container.assertShows();
  makeValid(elements.targetTPSInput, elements.tpsError);
  submit();
  pllTrainerElements.newUserStartPage.container.assertShows();

  function makeInvalid(inputElement: OurElement, errorElement: OurElement) {
    inputElement.get().type("abc", { delay: 0 });
    errorElement.waitFor();
  }
  function makeValid(inputElement: OurElement, errorElement: OurElement) {
    inputElement.get().type("{selectall}{backspace}2.0", { delay: 0 });
    errorElement.assertDoesntExist();
  }
}

function newUserStartPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.newUserStartPage;

  ([
    [
      "looks right",
      () => {
        // These elements should all display without scrolling
        elements.welcomeText.assertShows();
        elements.welcomeText.assertContainedByWindow();
        // These ones we accept possibly having to scroll for so just check it exists
        // We check it's visibility including scroll in the element sizing
        elements.assertAllConsumableViaVerticalScroll(
          elements.container.specifier
        );

        // A smoke test that we have added some links for the cubing terms
        elements.container.get().within(() => {
          cy.get("a").should("have.length.above", 0);
        });

        cy.assertNoHorizontalScrollbar();
      },
    ],
    [
      "doesn't start test when pressing other keys than space",
      () => {
        cy.pressKey(Key.a);
        elements.container.assertShows();
        cy.pressKey(Key.x);
        elements.container.assertShows();
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function newUserStartPageBeginNavigateVariant1() {
  pllTrainerElements.newUserStartPage.startButton.get().click();
  pllTrainerElements.newUserStartPage.container.assertDoesntExist();
}

function newUserStartPageBeginNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.newUserStartPage.container.assertDoesntExist();
}

function newUserStartPageEditTargetParamsNavigateVariant1() {
  pllTrainerElements.newUserStartPage.editTargetParametersButton.get().click();
  pllTrainerElements.newUserStartPage.container.assertDoesntExist();
}

function recurringUserStartPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.recurringUserStartPage;

  ([
    [
      "looks right",
      () => {
        // These elements should all display without scrolling
        [
          pllTrainerElements.recurringUserStartPage.numCasesTried,
          pllTrainerElements.recurringUserStartPage.numCasesNotYetTried,
          pllTrainerElements.recurringUserStartPage.worstThreeCases,
          pllTrainerElements.recurringUserStartPage.averageTPS,
          pllTrainerElements.recurringUserStartPage.averageTime,
        ].forEach((x) => {
          x.assertShows();
          x.assertContainedByWindow();
        });
        elements.assertAllConsumableViaVerticalScroll(
          elements.container.specifier
        );
        cy.assertNoHorizontalScrollbar();
        // A smoke test that we have added some links for the cubing terms
        pllTrainerElements.recurringUserStartPage.container.get().within(() => {
          cy.get("a").should("have.length.above", 0);
        });
      },
    ],
    [
      "doesn't start test when pressing other keys than space",
      () => {
        cy.pressKey(Key.a);
        elements.container.assertShows();
        cy.pressKey(Key.x);
        elements.container.assertShows();
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function recurringUserStartPageNavigateVariant1() {
  pllTrainerElements.recurringUserStartPage.startButton.get().click();
  pllTrainerElements.recurringUserStartPage.container.assertDoesntExist();
}

function recurringUserStartPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.recurringUserStartPage.container.assertDoesntExist();
}

function recurringUserStartPageEditTargetParamsNavigateVariant1() {
  pllTrainerElements.newUserStartPage.editTargetParametersButton.get().click();
  pllTrainerElements.newUserStartPage.container.assertDoesntExist();
}

function newCasePageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.newCasePage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
    [
      "doesn't start test when pressing other keys than space",
      () => {
        cy.pressKey(Key.a);
        elements.container.assertShows();
        cy.pressKey(Key.x);
        elements.container.assertShows();
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function newCasePageNavigateVariant1() {
  pllTrainerElements.newCasePage.startTestButton.get().click();
  pllTrainerElements.newCasePage.container.assertDoesntExist();
}

function newCasePageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.newCasePage.container.assertDoesntExist();
}

function getReadyStateNoSideEffectsButScroll() {
  const elements = pllTrainerElements.getReadyState;

  ([
    [
      "looks right",
      () => {
        elements.container.assertShows();
        elements.getReadyOverlay.assertShows();
        elements.getReadyExplanation.assertShows();
        // Since they are behind the overlay they don't actually show, so we just assert
        // they are contained by the window instead
        elements.timer.assertContainedByWindow();
        elements.cubePlaceholder.assertContainedByWindow();

        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function testRunningNoSideEffectsButScroll() {
  const elements = pllTrainerElements.testRunning;

  ([
    [
      "has all the correct elements",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

// TODO: If there is space for more navigation variants then adding more places
// to click here for both mouse and touch would be a good idea.
function testRunningNavigateVariant1() {
  cy.mouseClickScreen("topLeft");
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateVariant2() {
  cy.touchScreen("bottomRight");
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateVariant3() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.pressKey(Key.space);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateVariant4() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.pressKey(Key.w);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateVariant5() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.pressKey(Key.W);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateVariant6() {
  // Just a random "nonimportant" key, to make sure that works too
  cy.pressKey(Key.five);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant1() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.longPressKey(Key.space);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant2() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.longPressKey(Key.w);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant3() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.longPressKey(Key.W);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant4() {
  // Just a random "nonimportant" key, to make sure that works too
  cy.longPressKey(Key.five);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant5() {
  // button mash space before w
  cy.buttonMash([
    Key.l,
    Key.five,
    Key.shift,
    Key.space,
    Key.capsLock,
    Key.leftCtrl,
    Key.w,
    Key.W,
  ]);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant6() {
  // button mash w before space
  cy.buttonMash([
    Key.w,
    Key.W,
    Key.l,
    Key.five,
    Key.shift,
    Key.space,
    Key.capsLock,
    Key.leftCtrl,
  ]);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant7() {
  // Long button mash
  cy.longButtonMash([
    Key.w,
    Key.W,
    Key.l,
    Key.five,
    Key.shift,
    Key.space,
    Key.capsLock,
    Key.leftCtrl,
  ]);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function evaluateResultWhileIgnoringTransitionsNoSideEffects() {
  const elements = pllTrainerElements.evaluateResult;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
    [
      "doesn't change state when otherwise correct buttons or shortcuts are pressed",
      () => {
        elements.correctButton.get().click({ force: true });
        elements.wrongButton.get().click({ force: true });
        cy.pressKey(Key.space);
        cy.pressKey(Key.w);
        cy.pressKey(Key.W);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function evaluateResultAfterIgnoringTransitionsNoSideEffects() {
  const elements = pllTrainerElements.evaluateResult;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
    [
      "doesn't change state when mouse clicks or keyboard presses that shouldn't work are pressed",
      () => {
        ([
          "center",
          "top",
          "left",
          "right",
          "bottom",
          "topLeft",
          "topRight",
          "bottomRight",
          "bottomLeft",
        ] as const).forEach((position) => {
          cy.withOverallNameLogged(
            {
              name: "testing click",
              displayName: "TESTING CLICK",
              message: `position ${position}`,
            },
            () => {
              cy.get("body", { log: false }).click(position, { log: false });
            }
          );
        });

        [Key.leftCtrl, Key.five, Key.l].forEach((key) => {
          cy.withOverallNameLogged(
            {
              displayName: "TESTING KEY",
              message: "'" + getKeyValue(key) + "'",
            },
            () => {
              cy.pressKey(key, { log: false });
            }
          );
        });

        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function evaluateResultNavigateCorrectVariant1() {
  pllTrainerElements.evaluateResult.correctButton.get().click();
  pllTrainerElements.evaluateResult.container.assertDoesntExist();
}

function evaluateResultNavigateCorrectVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.evaluateResult.container.assertDoesntExist();
}

function evaluateResultNavigateWrongVariant1() {
  pllTrainerElements.evaluateResult.wrongButton.get().click();
  pllTrainerElements.evaluateResult.container.assertDoesntExist();
}

function evaluateResultNavigateWrongVariant2() {
  cy.pressKey(Key.w);
  pllTrainerElements.evaluateResult.container.assertDoesntExist();
}

function evaluateResultNavigateWrongVariant3() {
  cy.pressKey(Key.W);
  pllTrainerElements.evaluateResult.container.assertDoesntExist();
}

function pickAlgorithmPageFirstThingNoSideEffects() {
  ([
    [
      "auto focuses the algorithm input",
      () => {
        pllTrainerElements.pickAlgorithmPage.algorithmInput.assertIsFocused();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function pickAlgorithmPageSideEffectsExceptNavigations(
  firstPLL: PLL,
  changePLL: () => void,
  secondPLL: PLL
) {
  const elements = pllTrainerElements.pickAlgorithmPage;

  ([
    [
      "looks right",
      () => {
        // Shouldn't have error message on load
        pllTrainerElements.globals.anyErrorMessage.assertDoesntExist();
        elements.assertAllShow();
        // Produce a very long error and assert it still displays, and that it didn't
        // trigger any scrollbars
        pllTrainerElements.pickAlgorithmPage.algorithmInput
          .get()
          .type("U B F2 A ".repeat(20) + "{enter}", { delay: 0 });
        pllTrainerElements.pickAlgorithmPage.invalidTurnableError.assertShows();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();

        // The text should somehow communicate which pll we are picking an algorithm for
        pllTrainerElements.pickAlgorithmPage.explanationText
          .get()
          .should("contain.text", pllToPllLetters[firstPLL]);
      },
    ],
    [
      "has correct links",
      () => {
        type LocalAliases = {
          firstExpertLink: string;
        };
        // The page should have an AlgDB link to the case being picked for
        testAlgdbLink(firstPLL);
        // The page should have any type of expert guidance link, any further assertions
        // would make for too brittle tests
        pllTrainerElements.pickAlgorithmPage.expertPLLGuidanceLink
          .get()
          .should((link) => {
            expect(link.prop("tagName")).to.equal("A");
            // Assert it opens in new tab
            expect(link.attr("target"), "target").to.equal("_blank");
          })
          .then((link) => {
            const url =
              link.attr("href") ||
              "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid";
            // Check that the link actually works
            return cy
              .request(url)
              .its("status")
              .should("be.at.least", 200)
              .and("be.lessThan", 300)
              .then(() => url);
          })
          .setAlias<LocalAliases, "firstExpertLink">("firstExpertLink");

        // NOTE: Pll is changed to secondPLL from here on out
        changePLL();

        testAlgdbLink(secondPLL);
        pllTrainerElements.pickAlgorithmPage.expertPLLGuidanceLink
          .get()
          .should((link) => {
            expect(link.prop("tagName")).to.equal("A");
            // Assert it opens in new tab
            expect(link.attr("target"), "target").to.equal("_blank");
          })
          .then((link) => {
            const url =
              link.attr("href") ||
              "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid";
            // Check that the link actually works
            cy.request(url)
              .its("status")
              .should("be.at.least", 200)
              .and("be.lessThan", 300);
            return cy.getAliases<LocalAliases>().then((aliases) => ({
              previous: aliases.firstExpertLink,
              current: url,
            }));
          })
          .should(({ previous, current }) => {
            expect(previous).to.not.be.undefined;
            expect(current).to.not.deep.equal(previous);
          });

        function testAlgdbLink(currentPLL: PLL) {
          pllTrainerElements.pickAlgorithmPage.algDbLink
            .get()
            .should((link) => {
              expect(link.prop("tagName")).to.equal("A");
              // Assert it opens in new tab
              expect(link.attr("target"), "target").to.equal("_blank");

              expect(link.prop("href"), "href")
                .to.be.a("string")
                .and.contain("algdb.net")
                .and.satisfy(
                  (href: string) =>
                    href
                      .toLowerCase()
                      .endsWith(
                        "/" + pllToPllLetters[currentPLL].toLowerCase()
                      ),
                  "ends with /" + pllToPllLetters[currentPLL].toLowerCase()
                );
            })
            .then((link) => {
              // Check that the link actually works
              cy.request(
                link.attr("href") ||
                  "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid"
              )
                .its("status")
                .should("be.at.least", 200)
                .and("be.lessThan", 300);
            });
        }
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function pickAlgorithmNavigateVariant1(currentPLL: PLL) {
  pllTrainerElements.pickAlgorithmPage.algorithmInput
    .get()
    .type(
      "{selectall}{backspace}" + pllToAlgorithmString[currentPLL] + "{enter}",
      { delay: 0 }
    );
  pllTrainerElements.pickAlgorithmPage.container.assertDoesntExist();
}

function pickAlgorithmNavigateVariant2(currentPLL: PLL) {
  pllTrainerElements.pickAlgorithmPage.algorithmInput
    .get()
    .type("{selectall}{backspace}" + pllToAlgorithmString[currentPLL], {
      delay: 0,
    });
  pllTrainerElements.pickAlgorithmPage.submitButton.get().click();
  pllTrainerElements.pickAlgorithmPage.container.assertDoesntExist();
}

function correctPageNoSideEffects() {
  const elements = pllTrainerElements.correctPage;
  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
        assertFunctioningFeedbackButtonShows();
      },
    ],
    [
      "doesn't start test when pressing keys other than space",
      () => {
        cy.pressKey(Key.a);
        cy.pressKey(Key.x);
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function correctPageNavigateVariant1() {
  pllTrainerElements.correctPage.nextButton.get().click();
  pllTrainerElements.correctPage.container.assertDoesntExist();
}

function correctPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.correctPage.container.assertDoesntExist();
}

function TypeOfWrongPageNoSideEffects({
  originalExpectedCubeFront,
  originalExpectedCubeBack,
  nextExpectedCubeFront,
  nextExpectedCubeBack,
}: {
  originalExpectedCubeFront: string;
  originalExpectedCubeBack: string;
  nextExpectedCubeFront: string;
  nextExpectedCubeBack: string;
}) {
  const elements = pllTrainerElements.typeOfWrongPage;
  ([
    [
      "looks right",
      () => {
        // Make sure all elements present and no scrollbars
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();

        // Check all the cubes look right

        // The cube for 'no moves applied' should be the same state as the previous/original expected cube state
        assertCubeMatchesStateString(
          originalExpectedCubeFront,
          elements.noMoveCubeStateFront
        );
        assertCubeMatchesStateString(
          originalExpectedCubeBack,
          elements.noMoveCubeStateBack
        );
        // The cube for 'nearly there' should look like the expected state if you had
        // solved the case correctly
        assertCubeMatchesStateString(
          nextExpectedCubeFront,
          elements.nearlyThereCubeStateFront
        );
        assertCubeMatchesStateString(
          nextExpectedCubeBack,
          elements.nearlyThereCubeStateBack
        );
      },
    ],
    [
      "doesn't start test when pressing arbitrary keys",
      () => {
        // on purpose use some of the ones we often use like space and w
        [Key.space, Key.w, Key.W, Key.five, Key.d, Key.shift].forEach((key) => {
          cy.pressKey(key);
        });
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function typeOfWrongPageNoMovesNavigateVariant1() {
  pllTrainerElements.typeOfWrongPage.noMoveButton.get().click();
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function typeOfWrongPageNoMovesNavigateVariant2() {
  cy.pressKey(Key.one);
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function typeOfWrongPageNearlyThereNavigateVariant1() {
  pllTrainerElements.typeOfWrongPage.nearlyThereButton.get().click();
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function typeOfWrongPageNearlyThereNavigateVariant2() {
  cy.pressKey(Key.two);
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function typeOfWrongPageUnrecoverableNavigateVariant1() {
  pllTrainerElements.typeOfWrongPage.unrecoverableButton.get().click();
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function typeOfWrongPageUnrecoverableNavigateVariant2() {
  cy.pressKey(Key.three);
  pllTrainerElements.typeOfWrongPage.container.assertDoesntExist();
}

function algorithmDrillerExplanationPageNoSideEffectsButScroll({
  testCaseCube,
}: {
  testCaseCube: string;
}) {
  const elements = pllTrainerElements.algorithmDrillerExplanationPage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllConsumableViaVerticalScroll(
          elements.container.specifier
        );
        assertCubeMatchesStateString(testCaseCube, elements.caseToDrill);
        cy.assertNoHorizontalScrollbar();
      },
    ],
    [
      "doesn't start test when pressing keys other than space",
      () => {
        cy.pressKey(Key.a);
        cy.pressKey(Key.x);
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function algorithmDrillerExplanationPageNavigateVariant1() {
  pllTrainerElements.algorithmDrillerExplanationPage.continueButton
    .get()
    .click();
  pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist();
}

function algorithmDrillerExplanationPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.algorithmDrillerExplanationPage.container.assertDoesntExist();
}

function algorithmDrillerStatusPageNoSideEffects({
  solvedFront,
  solvedBack,
}: {
  solvedFront: string;
  solvedBack: string;
  // We are just adding this argument to make it clear what the requirements
  // are for the caller. That's also why only true is allowed
  expectedCubeStateWasNotSolvedBeforeThis: true;
}) {
  const elements = pllTrainerElements.algorithmDrillerStatusPage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
    [
      "the expected cube state at first is always solved even if expected cube state was not solved before",
      () => {
        assertCubeMatchesStateString(
          solvedFront,
          elements.expectedCubeStateFront
        );
        assertCubeMatchesStateString(
          solvedBack,
          elements.expectedCubeStateBack
        );
      },
    ],
    [
      "initial attempts left value reads 3",
      () => {
        elements.correctConsecutiveAttemptsLeft.get().should("have.text", "3");
      },
    ],
    [
      "doesn't start test when pressing keys other than space",
      () => {
        cy.pressKey(Key.a);
        cy.pressKey(Key.x);
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function algorithmDrillerStatusPageAfter1SuccessNoSideEffects({
  evaluateResultFront,
  evaluateResultBack,
}: {
  evaluateResultFront: string;
  evaluateResultBack: string;
}) {
  const elements = pllTrainerElements.algorithmDrillerStatusPage;

  elements.correctConsecutiveAttemptsLeft.get().should("have.text", "2");

  // Here we assert that the cube is displayed in the expected state
  assertCubeMatchesStateString(
    evaluateResultFront,
    elements.expectedCubeStateFront
  );
  assertCubeMatchesStateString(
    evaluateResultBack,
    elements.expectedCubeStateBack
  );
}

function algorithmDrillerStatusPageAfter1Success1FailureNoSideEffects() {
  pllTrainerElements.algorithmDrillerStatusPage.correctConsecutiveAttemptsLeft
    .get()
    .should("have.text", "3");
}

function algorithmDrillerStatusPageAfter2SuccessesNoSideEffects() {
  pllTrainerElements.algorithmDrillerStatusPage.correctConsecutiveAttemptsLeft
    .get()
    .should("have.text", "1");
}

function algorithmDrillerStatusPageNavigateVariant1() {
  pllTrainerElements.algorithmDrillerStatusPage.nextTestButton.get().click();
  pllTrainerElements.algorithmDrillerStatusPage.container.assertDoesntExist();
}

function algorithmDrillerStatusPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.algorithmDrillerStatusPage.container.assertDoesntExist();
}

function algorithmDrillerSuccessPageNoSideEffects() {
  const elements = pllTrainerElements.algorithmDrillerSuccessPage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();
      },
    ],
    [
      "doesn't start test when pressing keys other than space",
      () => {
        cy.pressKey(Key.a);
        cy.pressKey(Key.x);
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function algorithmDrillerSuccessPageNavigateVariant1() {
  pllTrainerElements.algorithmDrillerSuccessPage.nextTestButton.get().click();
  pllTrainerElements.algorithmDrillerSuccessPage.container.assertDoesntExist();
}

function algorithmDrillerSuccessPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.algorithmDrillerSuccessPage.container.assertDoesntExist();
}

function wrongPageNoSideEffects({
  currentTestCase,
  testCaseFront,
  testCaseBack,
}: {
  currentTestCase: [AUF, PLL, AUF];
  testCaseFront: string;
  testCaseBack: string;
  // It's important that the nearly there button was used because
  // otherwise expected state could be solved state which could avoid catching
  // a bug we actually (nearly) had in production where what was
  // displayed was the expectedCube with the inverse test case applied
  // to it instead of the solved cube with inverse test case
  nearlyThereTypeOfWrongWasUsed: true;
}) {
  const elements = pllTrainerElements.wrongPage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllShow();
        assertFunctioningFeedbackButtonShows();
        cy.assertNoHorizontalScrollbar();
        cy.assertNoVerticalScrollbar();

        // Test case cubes look correct
        assertCubeMatchesStateString(
          testCaseFront,
          pllTrainerElements.wrongPage.testCaseFront
        );
        assertCubeMatchesStateString(
          testCaseBack,
          pllTrainerElements.wrongPage.testCaseBack
        );
      },
    ],
    [
      "doesn't start test when pressing keys other than space",
      () => {
        cy.pressKey(Key.a);
        cy.pressKey(Key.x);
        cy.pressKey(Key.capsLock);
        elements.container.assertShows();
      },
    ],
    [
      "has the right correct answer text",
      () => {
        // Verify U and U2 display correctly
        const firstTestCase = [AUF.U, PLL.Aa, AUF.U2] as const;
        cy.setCurrentTestCase(firstTestCase);
        pllTrainerElements.wrongPage.testCaseName
          .get()
          .invoke("text")
          .should("match", testCaseToWrongPageRegex(firstTestCase));

        // Verify U' and nothing display correctly, while also trying a different PLL
        const secondTestCase = [AUF.UPrime, PLL.Ab, AUF.none] as const;
        cy.setCurrentTestCase(secondTestCase);
        pllTrainerElements.wrongPage.testCaseName
          .get()
          .invoke("text")
          .should("match", testCaseToWrongPageRegex(secondTestCase));

        // Verify no AUFs displays correctly and also trying a third PLL
        const thirdTestCase = [AUF.none, PLL.H, AUF.none] as const;
        cy.setCurrentTestCase(thirdTestCase);
        pllTrainerElements.wrongPage.testCaseName
          .get()
          .invoke("text")
          .should("match", testCaseToWrongPageRegex(thirdTestCase));

        // Reset to the previous test case, which is very important to uphold the
        // promise of no side effects
        cy.setCurrentTestCase(currentTestCase);
      },
    ],
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function testCaseToWrongPageRegex(testCase: readonly [AUF, PLL, AUF]): RegExp {
  const firstAufString = aufToAlgorithmString[testCase[0]];
  const secondAufString = aufToAlgorithmString[testCase[2]];
  return new RegExp(
    [
      firstAufString && String.raw`\b${firstAufString}\s+`,
      String.raw`[^\b]*${pllToPllLetters[testCase[1]]}[^\b]*`,
      secondAufString && String.raw`\s+${secondAufString}\b`,
    ].join("")
  );
}

function wrongPageNavigateVariant1() {
  pllTrainerElements.wrongPage.nextButton.get().click();
  pllTrainerElements.wrongPage.container.assertDoesntExist();
}

function wrongPageNavigateVariant2() {
  cy.pressKey(Key.space);
  pllTrainerElements.wrongPage.container.assertDoesntExist();
}

function assertFunctioningFeedbackButtonShows() {
  pllTrainerElements.globals.feedbackButton
    .assertShows()
    .parent()
    .within(() => {
      // It should be a link going to a google form
      cy.get("a")
        .should((linkElement) => {
          expect(linkElement.prop("href"), "href")
            .to.be.a("string")
            .and.satisfy(
              (href: string) => href.startsWith("https://forms.gle/"),
              "starts with https://forms.gle/"
            );
          // Asserts it opens in new tab
          expect(linkElement.attr("target"), "target").to.equal("_blank");
        })
        .then((link) => {
          // Check that the link actually works
          cy.request(
            link.attr("href") ||
              "http://veryinvaliddomainnameasdfasfasdfasfdas.invalid"
          )
            .its("status")
            .should("be.at.least", 200)
            .and("be.lessThan", 300);
        });
    });
}
