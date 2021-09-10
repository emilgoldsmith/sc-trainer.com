import { applyDefaultIntercepts } from "support/interceptors";
import { Key } from "support/keys";
import { paths } from "support/paths";
import { pllTrainerElements } from "../state-and-elements.helper";

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
      cy.visit(paths.pllTrainer, { onBeforeLoad: simulateIsTouchScreen });
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
      cy.visit(paths.pllTrainer);
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
  pllTrainerElements.newUserStartPage.container.waitFor();
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
  pllTrainerElements.getReadyScreen.container.waitFor();
  cy.tick(1000);
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
  pllTrainerElements.correctPage.container.waitFor();
  pllTrainerElements.correctPage.nextButton
    .get()
    .invoke("text")
    .should(matcher, buildShortcutRegex("Space"));

  if (method === "useKeyboard") {
    // Note this also checks the space shortcut actually works as the label implies
    cy.pressKey(Key.space);
  } else {
    pllTrainerElements.correctPage.nextButton.get().click();
  }
  pllTrainerElements.getReadyScreen.container.waitFor();
  cy.tick(1000);
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
  const typeOfWrongStateAlias = "type-of-wrong-state";
  cy.getApplicationState("type of wrong").as(typeOfWrongStateAlias);

  ([
    [pllTrainerElements.typeOfWrongPage.noMoveButton, "1", Key.one],
    [pllTrainerElements.typeOfWrongPage.nearlyThereButton, "2", Key.two],
    [pllTrainerElements.typeOfWrongPage.unrecoverableButton, "3", Key.three],
  ] as const).forEach(([element, shortcutText, key]) => {
    cy.getAliases(typeOfWrongStateAlias).then((state) => {
      if (!isOurApplicationState(state)) {
        throw new Error("Expected an application state variable here");
      }
      cy.setApplicationState(
        state as Cypress.OurApplicationState,
        "type of wrong"
      );
    });
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
  pllTrainerElements.getReadyScreen.container.waitFor();
}

function isOurApplicationState(
  possibleState: unknown
): possibleState is Cypress.OurApplicationState {
  return (
    typeof possibleState === "object" &&
    possibleState !== null &&
    "identifierToMakeItUnique" in possibleState &&
    (possibleState as Cypress.OurApplicationState).identifierToMakeItUnique ===
      "ourApplicationState"
  );
}

function buildShortcutRegex(shortcutText: string): RegExp {
  return new RegExp(String.raw`\(\s*${shortcutText}\s*\)`);
}
