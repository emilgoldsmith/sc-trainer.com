import { applyDefaultIntercepts } from "support/interceptors";
import { Key } from "support/keys";
import { forceReloadAndNavigateIfDotOnlyIsUsed } from "support/mocha-helpers";
import { AUF, PLL, pllToAlgorithmString } from "support/pll";
import {
  getReadyWaitTime,
  pllTrainerElements,
  pllTrainerStatesNewUser,
} from "../state-and-elements";

forceReloadAndNavigateIfDotOnlyIsUsed();

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
  beforeEach(function () {
    applyDefaultIntercepts();
  });
  context("touch screen", function () {
    beforeEach(function () {
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo({
        onBeforeLoad: simulateIsTouchScreen,
      });
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
      pllTrainerStatesNewUser.startPage.reloadAndNavigateTo();
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
  const testCase = [AUF.none, PLL.Aa, AUF.none] as const;
  cy.overrideNextTestCase(testCase);
  // Ensure that it's a fresh user
  pllTrainerElements.newUserStartPage.welcomeText.waitFor();
  pllTrainerElements.newUserStartPage.startButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.newUserStartPage.startButton.get().click();
  }

  pllTrainerElements.newCasePage.container.waitFor();
  pllTrainerElements.newCasePage.startTestButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.newCasePage.startTestButton.get().click();
  }

  pllTrainerElements.getReadyState.container.waitFor();
  cy.tick(getReadyWaitTime);
  pllTrainerElements.testRunning.container.waitFor();
  if (method === "useKeyboard") {
    cy.pressKey(Key.space);
  } else {
    cy.touchScreen("topLeft");
  }
  pllTrainerElements.evaluateResult.container.waitFor();
  pllTrainerElements.evaluateResult.correctButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  cy.tick(300);
  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.evaluateResult.correctButton.get().click();
  }
  // Note that we type before we check the shortcut text.
  // This ensures we check the case of a mobile keyboard
  // appearing for the input element and triggering
  // global keyboard detection which it shouldn't
  pllTrainerElements.pickAlgorithmPage.algorithmInput
    .get()
    .type(pllToAlgorithmString[PLL.Aa]);
  pllTrainerElements.pickAlgorithmPage.submitButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Enter"));
  if (method === "useKeyboard") {
    // Note this also checks the enter shortcut actually works as the label implies
    cy.pressKey(Key.enter);
  } else {
    pllTrainerElements.pickAlgorithmPage.submitButton.get().click();
  }
  pllTrainerElements.correctPage.container.waitFor();
  pllTrainerElements.correctPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  cy.overrideNextTestCase(testCase);
  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.correctPage.nextButton.get().click();
  }
  pllTrainerElements.getReadyState.container.waitFor();
  cy.tick(getReadyWaitTime);
  pllTrainerElements.testRunning.container.waitFor();

  // And now we go back to evaluateResult so we can do the wrong path
  if (method === "useKeyboard") {
    cy.pressKey(Key.space);
  } else {
    cy.touchScreen("topLeft");
  }
  pllTrainerElements.evaluateResult.container.waitFor();
  pllTrainerElements.evaluateResult.wrongButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("[wW]"));

  cy.tick(300);
  if (method === "useKeyboard") {
    // Note this also checks the w shortcut actually works as the label implies
    cy.pressKey(Key.w);
  } else {
    pllTrainerElements.evaluateResult.wrongButton.get().click();
  }
  pllTrainerElements.typeOfWrongPage.container.waitFor();

  // For easy return here to check all the branches
  cy.getApplicationState("type of wrong").then((typeOfWrongState) => {
    ([
      [pllTrainerElements.typeOfWrongPage.noMoveButton, "1", Key.one],
      [pllTrainerElements.typeOfWrongPage.nearlyThereButton, "2", Key.two],
      [pllTrainerElements.typeOfWrongPage.unrecoverableButton, "3", Key.three],
    ] as const).forEach(([element, shortcutText, key]) => {
      cy.setApplicationState(typeOfWrongState, "type of wrong");
      pllTrainerElements.typeOfWrongPage.container.waitFor();

      element
        .get()
        .invoke("text")
        .should(matcher, buildShortcutRegex(shortcutText));
      if (method === "useKeyboard") {
        // Note this also checks the given shortcut actually works as the label implies
        cy.pressKey(key);
      } else {
        element.get().click();
      }
      // Just making sure the navigation works as intended simply, it's more thoroughly checked in the main test
      pllTrainerElements.wrongPage.container.assertShows();
    });
  });

  cy.overrideNextTestCase(testCase);
  // And then we test wrong page works as intended too
  pllTrainerElements.wrongPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  if (method === "useKeyboard") {
    // Check space actually works as a shortcut too as the label implies.
    // This is just to make sure we're asserting the right thing.
    // It's more thoroughly checked in main test
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.wrongPage.nextButton.get().click();
  }
  pllTrainerElements.getReadyState.container.waitFor();
}

function buildShortcutRegex(shortcutText: string): RegExp {
  return new RegExp(String.raw`\(\s*${shortcutText}\s*\)`);
}
