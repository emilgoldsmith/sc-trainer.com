// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

import { getCode, getKeyCode, getKeyValue, Key } from "./keys";

const getByTestId: Cypress.Chainable<undefined>["getByTestId"] = (
  selector,
  ...args
) => cy.get(`[data-testid=${selector}]`, ...args);
Cypress.Commands.add("getByTestId", getByTestId);

const pressKey: Cypress.Chainable<undefined>["pressKey"] = function (key) {
  const event = buildKeyboardEvent(key);
  cy.withOverallNameLogged(
    {
      name: "pressKey",
      displayName: "PRESS KEY",
      message: `'${getKeyValue(key)}' without any dom target`,
      consoleProps: () => ({ event }),
    },
    () => {
      cy.document({ log: false })
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false })
        .trigger("keyup", { ...event, log: false });
    }
  );
};
Cypress.Commands.add("pressKey", pressKey);

function buildKeyboardEvent(
  key: Key
): KeyboardEventInit &
  Partial<Cypress.TriggerOptions> & { constructor: typeof KeyboardEvent } {
  return {
    key: getKeyValue(key),
    code: getCode(key),
    keyCode: getKeyCode(key),
    constructor: KeyboardEvent,
  };
}

const longPressKey: Cypress.Chainable<undefined>["longPressKey"] = function (
  key
) {
  // A somewhat arbitrary number that just is long enough for a very long press
  const LONG_TIME_MS = 3000;
  const stringDisplayableKey = "'" + getKeyValue(key) + "'";
  const event = buildKeyboardEvent(key);
  cy.withOverallNameLogged(
    {
      name: "longPressKey",
      displayName: "LONG PRESS KEY",
      message: `${stringDisplayableKey} without any dom target`,
      consoleProps: () => ({
        event,
        "Key Press Duration In Millisecond": LONG_TIME_MS,
      }),
    },
    () => {
      cy.document({ log: false })
        .trigger("keydown", { ...event, log: false })
        .trigger("keypress", { ...event, log: false });
      cy.log(`Pressed down ${stringDisplayableKey}`);
      cy.tick(LONG_TIME_MS);
      cy.document({ log: false })
        .trigger("keypress", { ...event, log: false })
        .trigger("keyup", { ...event, log: false });
      cy.log(`Released ${stringDisplayableKey}`);
    }
  );
};
Cypress.Commands.add("longPressKey", longPressKey);

const getCustomWindow: Cypress.Chainable<undefined>["getCustomWindow"] = function (
  options: {
    log?: boolean;
  } = {}
) {
  return cy.window(options).then((window) => {
    const customWindow = window as Cypress.CustomWindow;
    if (customWindow.END_TO_END_TEST_HELPERS === undefined) {
      throw new Error(
        "Not a populated custom window, doesn't have END_TO_END_TEST_HELPERS property"
      );
    }
    return customWindow;
  });
};
Cypress.Commands.add("getCustomWindow", getCustomWindow);

const getApplicationState: Cypress.Chainable<undefined>["getApplicationState"] = function (
  name
) {
  return cy.withOverallNameLogged(
    {
      name: "getApplicationState",
      displayName: "GET APPLICATION STATE",
      message: name === undefined ? "current" : `current ${name} state`,
      consoleProps: () => ({ name }),
    },
    (consolePropsSetter) =>
      cy.getCustomWindow({ log: false }).then((window) => {
        const state = window.END_TO_END_TEST_HELPERS.getModel();
        consolePropsSetter({ name, appState: state });
        return state;
      })
  );
};
Cypress.Commands.add("getApplicationState", getApplicationState);

const setApplicationState: Cypress.Chainable<undefined>["setApplicationState"] = function (
  state,
  name
) {
  if (state === undefined) {
    throw new Error(
      "setApplicationState called with undefined state, which is not allowed"
    );
  }
  const stateDescription = name || "unknown";
  cy.withOverallNameLogged(
    {
      name: "setApplicationState",
      displayName: "SET APPLICATION STATE",
      message: `to ${stateDescription} state`,
      consoleProps: () => ({ appState: state, name: stateDescription }),
    },
    () => {
      cy.getCustomWindow({ log: false }).then((window) =>
        window.END_TO_END_TEST_HELPERS.setModel(state)
      );
    }
  );
};
Cypress.Commands.add("setApplicationState", setApplicationState);

const withOverallNameLogged: Cypress.Chainable<undefined>["withOverallNameLogged"] = function (
  logConfig,
  commandsCallback
) {
  const log = Cypress.log({
    ...logConfig,
    ...(logConfig.autoEnd === true ? {} : { autoEnd: false }),
  });
  const consolePropsSetter = (consoleProps: Cypress.ObjectLike): void => {
    log.set({ consoleProps: () => consoleProps });
  };
  const handleEndOfCommand = () => {
    log.snapshot("after");
    if (logConfig.autoEnd !== true) {
      log.end();
    }
  };

  log.snapshot("before");
  const callbackReturnValue = commandsCallback(consolePropsSetter);
  if (Cypress.isCy(callbackReturnValue)) {
    return callbackReturnValue.then((returnValue) => {
      handleEndOfCommand();
      return returnValue;
    }) as typeof callbackReturnValue;
  } else {
    cy.wrap(undefined, { log: false }).then(handleEndOfCommand);
    return callbackReturnValue;
  }
};
Cypress.Commands.add("withOverallNameLogged", withOverallNameLogged);
