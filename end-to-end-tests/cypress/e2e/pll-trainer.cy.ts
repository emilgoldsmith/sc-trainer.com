import { assertCubeMatchesAlias } from "support/assertions";
import { OurElement } from "support/elements";
import { applyDefaultIntercepts } from "support/interceptors";
import { getKeyValue, Key } from "support/keys";
import { paths } from "support/paths";
import { AUF, PLL, pllToAlgorithmString, pllToPllLetters } from "support/pll";
import {
  evaluateResultIgnoreTransitionsWaitTime,
  getReadyWaitTime,
  pllTrainerElements,
} from "./pll-trainer/state-and-elements";

type Aliases = {
  solvedFront: string;
  solvedBack: string;
  testCaseCube: string;
  originalCubeFront: string;
  originalCubeBack: string;
  nextCubeFront: string;
  nextCubeBack: string;
  evaluateResultFront: string;
  evaluateResultBack: string;
};

describe("PLL Trainer", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
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
    cy.withOverallNameLogged(
      { message: "To New User Page" },
      pickTargetParametersNavigateVariant1
    );
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
      startPageNavigateVariant1
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
      .setAlias<Aliases, "originalCubeFront">("originalCubeFront");
    pllTrainerElements.evaluateResult.expectedCubeBack
      .getStringRepresentationOfCube()
      .setAlias<Aliases, "originalCubeBack">("originalCubeBack");
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
        .setAlias<Aliases, "testCaseCube">("testCaseCube");
      testRunningNavigateVariant2();
      cy.tick(evaluateResultIgnoreTransitionsWaitTime);
      pllTrainerElements.evaluateResult.expectedCubeFront
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "nextCubeFront">("nextCubeFront");
      pllTrainerElements.evaluateResult.expectedCubeBack
        .getStringRepresentationOfCube()
        .setAlias<Aliases, "nextCubeBack">("nextCubeBack");
      evaluateResultNavigateWrongVariant1();
    });
    cy.withOverallNameLogged({ message: "Type Of Wrong Page" }, () => {
      TypeOfWrongPageNoSideEffects();
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
        algorithmDrillerExplanationPageNoSideEffectsButScroll();
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
        algorithmDrillerStatusPageNoSideEffects({
          expectedCubeStateWasNotSolvedBeforeThis: true,
        });
      }
    );
    cy.withOverallNameLogged(
      {
        message:
          "Complete Three Drills Successfully, ending at Algorithm Driller Success Page",
      },
      () => {
        for (let i = 0; i < 3; i++) {
          if (i % 2 === 0) {
            cy.withOverallNameLogged(
              { message: "Status Page Navigate Variant 1" },
              algorithmDrillerStatusPageNavigateVariant1
            );
          } else {
            cy.withOverallNameLogged(
              { message: "Status Page Navigate Variant 2" },
              algorithmDrillerStatusPageNavigateVariant2
            );
          }
          pllTrainerElements.getReadyState.container.waitFor();
          cy.tick(getReadyWaitTime);
          pllTrainerElements.testRunning.container.waitFor();
          testRunningNavigateVariant3();
          pllTrainerElements.evaluateResult.container.waitFor();
          cy.tick(evaluateResultIgnoreTransitionsWaitTime);
          if (i === 0) {
            pllTrainerElements.evaluateResult.expectedCubeFront
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultFront">("evaluateResultFront");
            pllTrainerElements.evaluateResult.expectedCubeBack
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "evaluateResultBack">("evaluateResultBack");
          }
          evaluateResultNavigateCorrectVariant2();
          if (i === 0) {
            cy.withOverallNameLogged(
              { message: "After 1 success" },
              algorithmDrillerStatusPageAfter1SuccessNoSideEffects
            );
          } else if (i === 1) {
            cy.withOverallNameLogged(
              { message: "After 2 successes" },
              algorithmDrillerStatusPageAfter2SuccessesNoSideEffects
            );
          }
        }
      }
    );
    pllTrainerElements.algorithmDrillerSuccessPage.container.waitFor();
  });
});

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
  ] as const).forEach(([testDescription, testFunction]) =>
    cy.withOverallNameLogged({ message: testDescription }, testFunction)
  );
}

function pickTargetParametersNavigateVariant1() {
  testPickTargetParametersOnlySubmitsWithNoErrors(() =>
    pllTrainerElements.pickTargetParametersPage.submitButton.get().click()
  );
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

function startPageNavigateVariant1() {
  pllTrainerElements.newUserStartPage.startButton.get().click();
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
  cy.pressKey(Key.space);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant2() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.pressKey(Key.w);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant3() {
  // Extra interesting as it's used as a shortcut in evaluate result
  cy.pressKey(Key.W);
  pllTrainerElements.testRunning.container.assertDoesntExist();
}

function testRunningNavigateChangingClockVariant4() {
  // Just a random "nonimportant" key, to make sure that works too
  cy.pressKey(Key.five);
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

function TypeOfWrongPageNoSideEffects() {
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
        assertCubeMatchesAlias<Aliases, "originalCubeFront">(
          "originalCubeFront",
          elements.noMoveCubeStateFront
        );
        assertCubeMatchesAlias<Aliases, "originalCubeBack">(
          "originalCubeBack",
          elements.noMoveCubeStateBack
        );
        // The cube for 'nearly there' should look like the expected state if you had
        // solved the case correctly
        assertCubeMatchesAlias<Aliases, "nextCubeFront">(
          "nextCubeFront",
          elements.nearlyThereCubeStateFront
        );
        assertCubeMatchesAlias<Aliases, "nextCubeBack">(
          "nextCubeBack",
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

function algorithmDrillerExplanationPageNoSideEffectsButScroll() {
  const elements = pllTrainerElements.algorithmDrillerExplanationPage;

  ([
    [
      "looks right",
      () => {
        elements.assertAllConsumableViaVerticalScroll(
          elements.container.specifier
        );
        assertCubeMatchesAlias<Aliases, "testCaseCube">(
          "testCaseCube",
          elements.caseToDrill
        );
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

// We are just adding this argument to make it clear what the requirements
// are for the caller. That's also why only true is allowed
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function algorithmDrillerStatusPageNoSideEffects(_: {
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
        assertCubeMatchesAlias<Aliases, "solvedFront">(
          "solvedFront",
          elements.expectedCubeStateFront
        );
        assertCubeMatchesAlias<Aliases, "solvedBack">(
          "solvedBack",
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

function algorithmDrillerStatusPageAfter1SuccessNoSideEffects() {
  const elements = pllTrainerElements.algorithmDrillerStatusPage;

  elements.correctConsecutiveAttemptsLeft.get().should("have.text", "2");

  // Here we assert that the cube is displayed in the expected state
  assertCubeMatchesAlias<Aliases, "evaluateResultFront">(
    "evaluateResultFront",
    elements.expectedCubeStateFront
  );
  assertCubeMatchesAlias<Aliases, "evaluateResultBack">(
    "evaluateResultBack",
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
