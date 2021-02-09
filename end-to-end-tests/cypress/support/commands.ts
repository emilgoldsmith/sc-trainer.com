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

const pressKey: Cypress.Chainable<undefined>["pressKey"] = (key) => {
  const event = buildKeyboardEvent(key);
  cy.document()
    .trigger("keydown", event)
    .trigger("keypress", event)
    .trigger("keyup", event);
};
Cypress.Commands.add("pressKey", pressKey);

const longPressKey: Cypress.Chainable<undefined>["longPressKey"] = (key) => {
  const event = buildKeyboardEvent(key);
  cy.document().trigger("keydown", event).trigger("keypress", event);
  // A somewhat arbitrary number that just is long enough for a very long press
  cy.tick(3000);
  cy.document().trigger("keypress", event).trigger("keyup", event);
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
