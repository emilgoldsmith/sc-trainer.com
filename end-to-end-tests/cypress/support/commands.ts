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
  const log = Cypress.log({
    name: "pressKey",
    displayName: "PRESS KEY",
    message: `'${getKeyValue(key)}' without any dom target`,
    autoEnd: false,
    consoleProps: () => ({ event }),
  });
  log.snapshot("before");

  cy.document({ log: false })
    .trigger("keydown", { ...event, log: false })
    .trigger("keypress", { ...event, log: false })
    .trigger("keyup", { ...event, log: false });

  new Cypress.Promise(() => {
    log.snapshot("after");
    log.end();
  });
};
Cypress.Commands.add("pressKey", pressKey);

const longPressKey: Cypress.Chainable<undefined>["longPressKey"] = function (
  key
) {
  // A somewhat arbitrary number that just is long enough for a very long press
  const LONG_TIME_MS = 3000;
  const stringDisplayableKey = `'${getKeyValue(key)}'`;
  const event = buildKeyboardEvent(key);
  const log = Cypress.log({
    name: "longPressKey",
    displayName: "LONG PRESS KEY",
    message: `${stringDisplayableKey} without any dom target`,
    autoEnd: false,
    consoleProps: () => ({
      event,
      "Key Press Duration In Millisecond": LONG_TIME_MS,
    }),
  });
  log.snapshot("before");

  cy.document({ log: false })
    .trigger("keydown", { ...event, log: false })
    .trigger("keypress", { ...event, log: false });
  cy.log(`Pressed down ${stringDisplayableKey}`);
  cy.tick(LONG_TIME_MS);
  cy.document({ log: false })
    .trigger("keypress", { ...event, log: false })
    .trigger("keyup", { ...event, log: false });
  cy.log(`Released ${stringDisplayableKey}`);

  new Cypress.Promise(() => {
    log.snapshot("after");
    log.end();
  });
};
Cypress.Commands.add("longPressKey", longPressKey);

function buildKeyboardEvent(
  key: Key
): KeyboardEventInit & { constructor: typeof KeyboardEvent } {
  return {
    key: getKeyValue(key),
    code: getCode(key),
    keyCode: getKeyCode(key),
    constructor: KeyboardEvent,
  };
}

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
  const log = Cypress.log({
    name: "getApplicationState",
    displayName: "GET APPLICATION STATE",
    message: name === undefined ? "current" : `current ${name} state`,
    autoEnd: false,
    consoleProps: () => ({ name }),
  });
  return cy
    .getCustomWindow({ log: false })
    .then((window) => window.END_TO_END_TEST_HELPERS.getModel())
    .then((state) => {
      log.set({ consoleProps: () => ({ state, name }) });
      log.snapshot("after");
      log.end();
    });
};
Cypress.Commands.add("getApplicationState", getApplicationState);

const setApplicationState: Cypress.Chainable<undefined>["setApplicationState"] = function (
  state,
  name
) {
  const stateDescription = name || "unknown";
  const log = Cypress.log({
    name: "setApplicationState",
    displayName: "SET APPLICATION STATE",
    message: `to ${stateDescription} state`,
    autoEnd: false,
    consoleProps: () => ({ state }),
  });
  log.snapshot("before");
  cy.getCustomWindow({ log: false }).then((window) =>
    window.END_TO_END_TEST_HELPERS.setModel(state)
  );
  new Cypress.Promise(() => {
    log.snapshot("after");
    log.end();
  });
  return cy.wrap(undefined, { log: false });
};
Cypress.Commands.add("setApplicationState", setApplicationState);
