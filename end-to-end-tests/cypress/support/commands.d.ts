/// <reference types="cypress" />

declare namespace Cypress {
  interface Chainable<Subject> {
    /**
     * Get an html node based on it's data-testid property set in our
     * html code to reliably target parts of our DOM.
     *
     * @example
     * // The HTML
     * <div data-testid="some-test-id"></div>
     * // The test code
     * cy.getByTestid("some-test-id");
     */
    getByTestId(
      ...args: Parameters<Cypress.Chainable<Subject>["get"]>
    ): Chainable<JQuery<HTMLElement>>;
    /**
     * Presses a key in the "global scope", not focusing on any specific node
     *
     * @example
     * cy.pressKey(Key.space);
     */
    pressKey(key: import("./keys").Key): void;
    /**
     * Holds down a key in the global scope for a "long" time before releasing it
     * not focusing on any specific node
     *
     * @example
     * cy.longPressKey(Key.space);
     */
    longPressKey(key: import("./keys").Key): void;
  }
}
