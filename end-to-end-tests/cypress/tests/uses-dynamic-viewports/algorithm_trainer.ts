// The single case hooks are nice for formatting in this case
/* eslint-disable mocha/no-hooks-for-single-case */
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
    context("large viewport", function () {
      beforeEach(function () {
        cy.viewport("macbook-15");
      });
      it("displays shortcuts on large viewport with touch screen", function () {
        assertShortcutsDisplay();
      });
    });
    context("small viewport", function () {
      beforeEach(function () {
        cy.viewport("iphone-8");
      });
      it("doesnt display shortcuts by default on small viewport with touch screen", function () {
        assertShortcutsDontDisplay();
      });
      it("displays shortcuts on small viewport with touch screen if a keyboard event was fired", function () {
        cy.pressKey(Key.leftCtrl);
        assertShortcutsDisplay();
      });
    });
  });
  context("non touch screen", function () {
    beforeEach(function () {
      cy.visit("/");
      cy.clock();
    });
    context("large viewport", function () {
      beforeEach(function () {
        cy.viewport("macbook-15");
      });
      it("displays shortcuts on a large viewport without touch screen", function () {
        assertShortcutsDisplay();
      });
    });
    context("small viewport", function () {
      beforeEach(function () {
        cy.viewport("iphone-8");
      });
      it("displays shortcuts on a small viewport with no touch screen", function () {
        assertShortcutsDisplay();
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
function assertShortcutsDisplay() {
  checkShortcutDisplays("match");
}

function assertShortcutsDontDisplay() {
  checkShortcutDisplays("not.match");
}

function checkShortcutDisplays(matcher: "match" | "not.match") {
  elements.startPage.container.waitFor();
  elements.startPage.startButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  // Note this also checks the space shortcut actually works
  cy.pressKey(Key.space);
  elements.getReadyScreen.container.waitFor();
  cy.tick(1000);
  elements.testRunning.container.waitFor();
  cy.pressKey(Key.space);
  elements.evaluateResult.container.waitFor();
  elements.evaluateResult.correctButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  // Note this also checks the space shortcut actually works
  cy.tick(300);
  cy.pressKey(Key.space);
  elements.correctPage.container.waitFor();
  elements.correctPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  // Note this also checks the space shortcut actually works
  cy.pressKey(Key.space);
  elements.getReadyScreen.container.waitFor();
  cy.tick(1000);
  elements.testRunning.container.waitFor();

  // And now we go back to evaluateResult so we can do the wrong path
  cy.pressKey(Key.space);
  elements.evaluateResult.container.waitFor();
  elements.evaluateResult.wrongButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*[wW]\s*\)/);

  // Note this also checks the w shortcut actually works
  cy.tick(300);
  cy.pressKey(Key.w);
  elements.wrongPage.container.waitFor();
  elements.wrongPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, /\(\s*Space\s*\)/);

  // Check space actually works as a shortcut too, just to make sure we're
  // asserting the right thing. It's more thoroughly checked in main test
  cy.pressKey(Key.space);
  elements.getReadyScreen.container.waitFor();
}
