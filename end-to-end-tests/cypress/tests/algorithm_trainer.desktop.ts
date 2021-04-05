import { Key } from "support/keys";

const elements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    startButton: "start-button",
  }),
  testRunning: buildElementsCategory({
    container: "test-running-container",
  }),
  evaluateResult: buildElementsCategory({
    container: "evaluate-test-result-container",
    correctButton: "correct-button",
    wrongButton: "wrong-button",
  }),
  correctPage: buildElementsCategory({
    container: "correct-container",
    nextButton: "next-button",
  }),
  wrongPage: buildElementsCategory({
    container: "wrong-container",
    nextButton: "next-button",
  }),
};

describe("Algorithm Trainer Desktop Only", function () {
  it("Displays keyboard shortcuts on all buttons", function () {
    cy.visit("/");
    cy.clock();
    elements.startPage.container.waitFor();
    elements.startPage.startButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.pressKey(Key.space);
    elements.testRunning.container.waitFor();
    cy.pressKey(Key.space);
    elements.evaluateResult.container.waitFor();
    elements.evaluateResult.correctButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.tick(300);
    cy.pressKey(Key.space);
    elements.correctPage.container.waitFor();
    elements.correctPage.nextButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Note this also checks the space shortcut actually works
    cy.pressKey(Key.space);
    elements.testRunning.container.waitFor();

    // And now we go back to evaluateResult so we can do the wrong path
    cy.pressKey(Key.space);
    elements.evaluateResult.container.waitFor();
    elements.evaluateResult.wrongButton
      .get()
      .invoke("text")
      .should("match", /\(\s*[wW]\s*\)/);

    // Note this also checks the w shortcut actually works
    cy.tick(300);
    cy.pressKey(Key.w);
    elements.wrongPage.container.waitFor();
    elements.wrongPage.nextButton
      .get()
      .invoke("text")
      .should("match", /\(\s*Space\s*\)/);

    // Check space actually works as a shortcut too, just to make sure we're
    // asserting the right thing. It's more thoroughly checked in main test
    cy.pressKey(Key.space);
    elements.testRunning.container.waitFor();
  });
});

function buildElementsCategory<keys extends string>(
  testIds: { container: string } & {
    [key in keys]: string;
  }
): {
  container: {
    get: ReturnType<typeof buildGetter>;
    waitFor: ReturnType<typeof buildWaiter>;
    assertShows: ReturnType<typeof buildAsserter>;
  };
} & {
  [key in keys]: {
    get: ReturnType<typeof buildGetter>;
    waitFor: ReturnType<typeof buildWaiter>;
    assertShows: ReturnType<typeof buildAsserter>;
  };
} {
  const getContainer = buildGetter(testIds.container);
  function buildWithinContainer(
    builder: typeof buildGetter,
    testId: string
  ): ReturnType<typeof buildGetter> {
    const fn = builder(testId);
    return function (...args: Parameters<ReturnType<typeof buildGetter>>) {
      return getContainer({ log: false }).then((containerElement) => {
        let options = args[0];
        if (!options) {
          options = { withinSubject: containerElement };
        } else if (options.withinSubject === undefined) {
          options.withinSubject = containerElement;
        }
        return fn(options);
      });
    };
  }

  return Cypress._.mapValues(testIds, (testId: string, key: string) => {
    if (key === "container") {
      return {
        get: buildGetter(testId),
        waitFor: buildWaiter(testId),
        assertShows: buildAsserter(testId),
      };
    }
    return {
      get: buildWithinContainer(buildGetter, testId),
      waitFor: buildWithinContainer(buildWaiter, testId),
      assertShows: buildWithinContainer(buildAsserter, testId),
    };
  }) as {
    container: {
      get: ReturnType<typeof buildGetter>;
      waitFor: ReturnType<typeof buildWaiter>;
      assertShows: ReturnType<typeof buildAsserter>;
    };
  } & {
    [key in keys]: {
      get: ReturnType<typeof buildGetter>;
      waitFor: ReturnType<typeof buildWaiter>;
      assertShows: ReturnType<typeof buildAsserter>;
    };
  };
}
function buildAsserter(testId: string) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options).should("be.visible");
  };
}

function buildWaiter(testId: string) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options);
  };
}

function buildGetter(testId: string) {
  return function (options?: {
    log?: boolean;
    withinSubject?: HTMLElement | JQuery<HTMLElement> | null;
  }) {
    return cy.getByTestId(testId, options);
  };
}
