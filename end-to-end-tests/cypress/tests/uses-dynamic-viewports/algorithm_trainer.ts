import { buildElementsCategory } from "support/elements";
import { Key } from "support/keys";

const elements = {
  startPage: buildElementsCategory({
    container: "start-page-container",
    startButton: "start-button",
  }),
  getReadyScreen: buildElementsCategory({
    container: "get-ready-container",
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

/** iphone-8 dimensions from https://docs.cypress.io/api/commands/viewport#Arguments */
const smallViewportConfigOverride: Cypress.TestConfigOverrides = {
  viewportWidth: 375,
  viewportHeight: 667,
};

/** macbook-15 dimensions from https://docs.cypress.io/api/commands/viewport#Arguments */
const largeViewportConfigOverride: Cypress.TestConfigOverrides = {
  viewportWidth: 1440,
  viewportHeight: 900,
};
/**
 * 1. A large touch screen shows shortcuts
 * 2. A large non touch screen shows shortcuts
 * 3. A small non touch screen shows shortcuts
 * 4. A small touch screen doesn't show shortcuts by default
 * 5. A small touch screen after a keyboard event shows shortcuts
 */

describe("Algorithm Trainer Dynamic Viewport Tests", function () {
  context("touch screen", function () {
    beforeEach(function () {
      cy.visit("/", { onBeforeLoad: simulateIsTouchScreen });
      cy.clock();
    });
    context("large viewport", largeViewportConfigOverride, function () {
      it("displays shortcuts on large viewport with touch screen", function () {
        assertShortcutsDisplay("useMouseAndButtons");
      });
    });
    context("small viewport", smallViewportConfigOverride, function () {
      it("doesnt display shortcuts by default on small viewport with touch screen", function () {
        assertShortcutsDontDisplay("useMouseAndButtons");
      });
      it("displays shortcuts on small viewport with touch screen if a keyboard event was fired", function () {
        cy.pressKey(Key.leftCtrl);
        assertShortcutsDisplay("useMouseAndButtons");
      });
    });
  });
  context("non touch screen", function () {
    /** For a non touch screen we should always show shortcuts as they must have a keyboard */
    beforeEach(function () {
      cy.visit("/");
      cy.clock();
    });
    context("large viewport", largeViewportConfigOverride, function () {
      it("displays shortcuts on a large viewport without touch screen", function () {
        assertShortcutsDisplay("useKeyboard");
      });
    });
    context("small viewport", smallViewportConfigOverride, function () {
      it("displays shortcuts on a small viewport with no touch screen", function () {
        assertShortcutsDisplay("useKeyboard");
      });
    });
  });
});

function simulateIsTouchScreen(testWindow: Window) {
  // We need to use defineProperty as it's a read only property, so this
  // is the only way to modify it. We use maxTouchPoints as a proxy for if
  // a touch screen is available due to
  // https://developer.mozilla.org/en-US/docs/Web/HTTP/Browser_detection_using_the_user_agent#Mobile_Device_Detection
  // which is the way we are currently doing "feature detection" on touch screen.
  // Of course modify this function if we change the way we detect a touch screen
  // though preferably by adding more things rather than removing the below
  // as that'll keep making it less brittle
  Object.defineProperty(testWindow.navigator, "maxTouchPoints", {
    get() {
      return 1;
    },
  });
}

function assertShortcutsDisplay(method: "useKeyboard" | "useMouseAndButtons") {
  checkWhetherShortcutsDisplay("match", method);
}

function assertShortcutsDontDisplay(
  method: "useKeyboard" | "useMouseAndButtons"
) {
  checkWhetherShortcutsDisplay("not.match", method);
}

function checkWhetherShortcutsDisplay(
  matcher: "match" | "not.match",
  method: "useKeyboard" | "useMouseAndButtons"
) {
  elements.startPage.container.waitFor();
  elements.startPage.startButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    elements.startPage.startButton.get().click();
  }
  elements.getReadyScreen.container.waitFor();
  cy.tick(1000);
  elements.testRunning.container.waitFor();
  if (method === "useKeyboard") {
    cy.pressKey(Key.space);
  } else {
    cy.touchScreen("topLeft");
  }
  elements.evaluateResult.container.waitFor();
  elements.evaluateResult.correctButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  cy.tick(300);
  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    elements.evaluateResult.correctButton.get().click();
  }
  elements.correctPage.container.waitFor();
  elements.correctPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    elements.correctPage.nextButton.get().click();
  }
  elements.getReadyScreen.container.waitFor();
  cy.tick(1000);
  elements.testRunning.container.waitFor();

  // And now we go back to evaluateResult so we can do the wrong path
  if (method === "useKeyboard") {
    cy.pressKey(Key.space);
  } else {
    cy.touchScreen("topLeft");
  }
  elements.evaluateResult.container.waitFor();
  elements.evaluateResult.wrongButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*[wW]\s*\)/);

  cy.tick(300);
  if (method === "useKeyboard") {
    // Note this also checks the w shortcut actually works as the label implies
    cy.pressKey(Key.w);
  } else {
    elements.evaluateResult.wrongButton.get().click();
  }
  elements.wrongPage.container.waitFor();
  elements.wrongPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  if (method === "useKeyboard") {
    // Check space actually works as a shortcut too as the label implies.
    // This is just to make sure we're asserting the right thing.
    // It's more thoroughly checked in main test
    cy.pressKey(Key.space);
  } else {
    elements.wrongPage.nextButton.get().click();
  }
  elements.getReadyScreen.container.waitFor();
}
