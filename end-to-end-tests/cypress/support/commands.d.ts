/// <reference types="cypress" />

declare namespace Cypress {
  import { Key } from "./keys";

  type CustomWindow = Window &
    typeof globalThis & {
      END_TO_END_TEST_HELPERS: {
        /**
         * Get a snapshot of the current application state
         */
        getModel(): OurApplicationState;
        /**
         * Reset the application state to a previous snapshot
         */
        setModel(newModel: Cypress.OurApplicationState): void;
        /**
         * Get all the event listeners currently active on document
         */
        getDocumentEventListeners(): Set<keyof DocumentEventMap>;
        /**
         * Only meant to be used within the javascript injection,
         * not ever within Cypress code
         */
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
   * going to be passing around an 'any type', as it will be passed in
   * from untyped code, but this ensures we
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
     *
     * @example
     *
     * cy.getCustomWindow().then(window => {
     *   return window.END_TO_END_TEST_HELPERS.getModel();
     * })
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
    pressKey(key: Key, options?: { log?: boolean }): void;

    /**
     * Holds down a key in the global scope for a "long" time before releasing it
     * not focusing on any specific node
     *
     * Requires cy.clock() time mocking beforehand
     *
     * @example
     * cy.clock();
     * cy.longPressKey(Key.space);
     */
    longPressKey(key: Key, options?: { log?: boolean }): void;

    /**
     * Simulates something like a hand smashing down on the given keys on the keyboard
     *
     * Requires cy.clock() time mocking beforehand
     *
     * @example
     * cy.clock();
     * cy.buttonMash([Key.space, Key.l, Key.leftCtrl]);
     */
    buttonMash(keys: Key[], options?: { log?: boolean }): void;

    /**
     * Simulates something like a hand smashing down on the given keys on the keyboard
     * and then taking a long time to release the keys
     *
     * Requires cy.clock() time mocking beforehand
     *
     * @example
     * cy.clock();
     * cy.longButtonMash([Key.space, Key.l, Key.leftCtrl]);
     */
    longButtonMash(keys: Key[], options?: { log?: boolean }): void;

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
    getApplicationState(
      name?: string,
      options?: { log?: boolean }
    ): Chainable<OurApplicationState>;

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
    setApplicationState(
      state: OurApplicationState,
      name?: string,
      options?: { log?: boolean }
    ): void;

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

    /**
     * Wait for the given document event listeners to be present
     *
     * @example
     * cy.waitForDocumentEventListeners("mousedown", "keydown");
     */
    waitForDocumentEventListeners(
      ...eventNames: (keyof DocumentEventMap)[]
    ): void;

    assertNoVerticalScrollbar(): void;

    assertNoHorizontalScrollbar(): void;

    touchScreen(position: Cypress.PositionType): void;

    mouseClickScreen(position: Cypress.PositionType): void;
  }
}
