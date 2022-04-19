/// <reference types="cypress" />

declare namespace Cypress {
  type ElmPorts = {
    [portName: string]:
      | {
          send: (value: any) => void;
          subscribe: (callback: (messageValue: any) => void) => void;
        }
      | undefined;
  };

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
         * The Elm Ports interface for the application
         */
        getPorts(): ElmPorts;
        /**
         * Only meant to be used within the javascript injection,
         * not ever within Cypress code
         */
        internal: {
          setModel(newModel: OurApplicationState): void;
          registerModelUpdater(
            updater: (newModel: OurApplicationState) => void
          ): void;
          setPorts(ports: ElmPorts): void;
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
     * // Specify ancestor parent ids (in order from highest ancestor to lowest) to look within
     * cy.getByTestId(["grandparent-test-id", "parent-test-id", "some-test-id"]);
     */
    getByTestId(
      testId: string | null,
      options?: Parameters<Cypress.Chainable<undefined>["get"]>[1] & {
        testType?: string;
      }
    ): Chainable<JQuery<HTMLElement>>;

    /**
     * Get a specific alias previously set with {@link Cypress.Chainable.setAlias}. See those docs for more info.
     * The long name is because getAlias is internally reserved command used by the Cypress team
     *
     * Sadly Typescript doesn't have partial type argument inference so you a bit awkwardly need to provide
     * the key both in the type argument and in the function argument in order to get the full type information
     */
    getSingleAlias<
      Aliases extends Record<string, unknown>,
      Key extends keyof Aliases
    >(
      alias: Key
    ): Chainable<Aliases[Key]>;
    /**
     * Get all the aliases previously set with {@link Cypress.Chainable.setAlias}. See those docs for more info
     */
    getAliases<Aliases extends Record<string, unknown>>(): Chainable<
      Partial<Aliases>
    >;

    /**
     * Definitely playing with some type magic here, and sadly Typescript doesn't support partial
     * type argument inference as can be seen here: https://github.com/Microsoft/TypeScript/issues/26242
     * I think that's something we can live with given that it gives us type safety,
     * ensuring a type error if we are giving the wrong subject to an alias.
     *
     * The intended use is that you define a scoped aliases type in your test
     * such as
     *
     * @example
     * type Aliases = {first: string, second: number};
     * // ...
     * cy.get(first).setAlias<Aliases, "first">("first");
     * // ...
     * cy.getSingleAlias<Aliases, "first">("first").then(x => {...});
     *
     * @description Note that you are managing the types yourself though,
     * so if you don't pass the same type to all the function calls you
     * could get in trouble
     */
    setAlias<
      Aliases extends Record<string, unknown>,
      Key extends keyof Aliases
    >(
      alias: Aliases[Key] extends Subject ? Key : never
    ): void;

    /**
     * Presses a key in the "global scope", not focusing on any specific node
     *
     * @example
     * cy.pressKey(Key.space);
     */
    pressKey(key: import("./keys").Key, options?: { log?: boolean }): void;

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
    longPressKey(key: import("./keys").Key, options?: { log?: boolean }): void;

    /**
     * Simulates something like a hand smashing down on the given keys on the keyboard
     *
     * Requires cy.clock() time mocking beforehand
     *
     * @example
     * cy.clock();
     * cy.buttonMash([Key.space, Key.l, Key.leftCtrl]);
     */
    buttonMash(keys: import("./keys").Key[], options?: { log?: boolean }): void;

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
    longButtonMash(
      keys: import("./keys").Key[],
      options?: { log?: boolean }
    ): void;

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

    percySnapshotWithProperName(
      name: string,
      options?: import("@percy/core").SnapshotOptions & {
        ensureFullHeightIsCaptured?: boolean;
      }
    ): void;

    setCurrentTestCase(
      testCase: readonly [
        import("./pll").AUF,
        import("./pll").PLL,
        import("./pll").AUF
      ]
    ): void;

    setLocalStorage(storageState: { [key: string]: any }): void;

    setExtraAlgToApplyToAllCubes(alg: string): void;

    setCubeSizeOverride(size: number | null): void;
  }
}

/** This is in the internal API in the current version anyway and very useful */
declare namespace Mocha {
  interface Suite {
    hasOnly(): boolean;
  }
}
