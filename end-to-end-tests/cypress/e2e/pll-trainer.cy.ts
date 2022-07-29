import { OurElement } from "support/elements";
import { applyDefaultIntercepts } from "support/interceptors";
import { getKeyValue, Key } from "support/keys";
import { paths } from "support/paths";
import { AUF, PLL, pllToAlgorithmString, pllToPllLetters } from "support/pll";
import {
  getReadyWaitTime,
  pllTrainerElements,
} from "./pll-trainer/state-and-elements";

describe("PLL Trainer", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
  });

  it("todo", function () {
    cy.visit(paths.pllTrainer);
    pllTrainerElements.pickTargetParametersPage.container.waitFor();
    let currentTestCase: [AUF, PLL, AUF] = [AUF.U, PLL.Ga, AUF.none];
    cy.overrideNextTestCase(currentTestCase);
    function getUpdatedTestCase() {
      // Do it with a wrap like this to properly go to the right place
      // in the async loop
      return cy.wrap(null, { log: false }).then(() => currentTestCase);
    }
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
    testRunningNavigateVariant1();
    cy.withOverallNameLogged(
      { message: "Evaluate Result Page While Ignoring Transitions" },
      evaluateResultWhileIgnoringTransitionsNoSideEffects
    );
    cy.tick(300);
    cy.withOverallNameLogged(
      { message: "Evaluate Result Page After Ignoring Transitions" },
      evaluateResultAfterIgnoringTransitionsNoSideEffects
    );
    evaluateResultNavigateVariant1();
    cy.withOverallNameLogged({ message: "Pick Algorithm Page" }, () => {
      getUpdatedTestCase().then(([, currentPLL]) => {
        const nextCase: [AUF, PLL, AUF] = [AUF.U2, PLL.Gb, AUF.UPrime];
        function changePLL() {
          currentTestCase = nextCase;
          cy.setCurrentTestCase(currentTestCase);
        }
        pickAlgorithmPageFirstThingNoSideEffects();
        pickAlgorithmPageSideEffectsExceptNavigations(
          currentPLL,
          changePLL,
          nextCase[1]
        );
      });
    });
    getUpdatedTestCase().then(([, currentPLL]) =>
      pickAlgorithmNavigateVariant1(currentPLL)
    );
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
  cy.mouseClickScreen("center");
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

function evaluateResultNavigateVariant1() {
  pllTrainerElements.evaluateResult.correctButton.get().click();
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
        type Aliases = {
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
          .setAlias<Aliases, "firstExpertLink">("firstExpertLink");

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
            return cy.getAliases<Aliases>().then((aliases) => ({
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
