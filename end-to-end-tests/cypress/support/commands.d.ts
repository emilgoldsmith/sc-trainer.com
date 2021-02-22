/// <reference types="cypress" />

declare namespace Cypress {
  import { Key } from "./keys";
  type CustomWindow = Window &
    typeof globalThis & {
      END_TO_END_TEST_HELPERS: {
        getModel(): OurApplicationState;
        setModel(newModel: Cypress.OurApplicationState): void;
        internal: {
          setModel(newModel: OurApplicationState): void;
          registerModelUpdater(
            updater: (newModel: OurApplicationState) => void
          ): void;
        };
      };
    };

  /**
   * A "fake type" for our application state as we're essentially
   * going to be passing around an 'any type', but this ensures we
   * will not be trying to modify it or construct it, only get it
   * from these functions and pass in ones we already got which
   * is the intention of this type
   */
  type OurApplicationState = {
    identifierToMakeItUnique: "ourApplicationState";
  };

  interface Chainable<Subject> {
    /**
     * Gets the window variable, but also asserts that it has our custom additions
     * to the window for test purposes and returns the extended window type
     */
    getCustomWindow(options?: {
      log?: boolean;
    }): Cypress.Chainable<CustomWindow>;

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

    pressKey(key: Key): void;
    /**
     * Holds down a key in the global scope for a "long" time before releasing it
     * not focusing on any specific node
     *
     * @example
     * cy.longPressKey(Key.space);
     */

    longPressKey(key: Key): void;
    /**
     * Get the current state of our application, do not try to modify it
     * just pass it in to setApplicationState at some point later to restore
     * the app to that state
     *
     * @example
     * cy.getApplicationState().then(state => {
     *   // Do something here
     *   return cy.setApplicationState(state);
     * })
     */
    getApplicationState(name?: string): Chainable<OurApplicationState>;

    /**
     * Restore the state of the application to a previous state.
     * Only use with a state gotten from cy.getApplicationState()
     *
     * @example
     * cy.getApplicationState().then(state => {
     *   // Do something here
     *   return cy.setApplicationState(state);
     * })
     */
    setApplicationState(state: OurApplicationState, name?: string): void;

    /**
     * Creates a log that the rest of the commands are nested under and
     * it will also track progress of the commands in the parent log
     *
     * @example
     * // When consoleProps are not used or known up front
     * cy.withOverallNameLogged({ displayName: "SOME COMMAND" }, () => {
     *   cy.get("something").should("not.exist");
     *   cy.click("button-selector");
     *   cy.get("something").should("exist");
     * });
     *
     * // When consoleProps are needed and not known up front
     * cy.withOverallNameLogged({ displayName: "SOME COMMAND" }, (consolePropsSetter) => {
     *   cy.get("something").should("not.exist");
     *   cy.click("button-selector");
     *   cy.get("something").should("exist").then(element => {
     *     consolePropsSetter({ keyName: element.someProperty })
     *   });
     * });
     */
    withOverallNameLogged<T>(
      logConfig: Partial<LogConfig>,
      commandsCallback: (
        consolePropsSetter: (
          props: ReturnType<LogConfig["consoleProps"]>
        ) => void
      ) => T
    ): T;
  }
}
