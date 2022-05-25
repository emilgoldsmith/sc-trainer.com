import { applyDefaultIntercepts } from "./interceptors";

let forceReloadAndNavigate = false;

export function setForceReloadAndNavigate(): void {
  forceReloadAndNavigate = true;
}

export type StateOptions = {
  log?: boolean;
  retainCurrentLocalStorage?: boolean;
  onBeforeLoad?: (window: Window) => void;
};
export interface StateCache<
  ExtraNavigateOptions extends Record<string, unknown>
> {
  populateCache(): void;
  restoreState(
    options?: StateOptions & {
      navigateOptionsForNavigateOverrides?: ExtraNavigateOptions;
    }
  ): void;
  reloadAndNavigateTo(
    options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
  ): void;
}

class StateCacheImplementation<
  Keys extends string,
  ExtraNavigateOptions extends Record<string, unknown>
> implements StateCache<ExtraNavigateOptions> {
  private elmModel: Cypress.OurApplicationState | null = null;
  private otherCaches?: {
    [key in Keys]: StateCacheImplementation<Keys, ExtraNavigateOptions>;
  };

  constructor(
    private name: string,
    private startPath: string,
    private getToThatState: (
      getState: (key: Keys) => void,
      options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
    ) => void,
    private defaultNavigateOptions: ExtraNavigateOptions,
    private waitForStateToAppear: (options?: StateOptions) => void,
    private localStorage?: { [key: string]: unknown }
  ) {}

  populateCache(
    interceptArgs?: Parameters<typeof applyDefaultIntercepts>[0]
  ): void {
    if (forceReloadAndNavigate) {
      cy.log("SKIPPED POPULATING CACHE");
      return;
    }
    applyDefaultIntercepts(interceptArgs);
    cy.withOverallNameLogged(
      {
        displayName: "POPULATING CACHE FOR STATE",
        message: this.name,
      },
      (consolePropsSetter) => {
        if (this.localStorage) cy.setLocalStorage(this.localStorage);
        cy.visit(this.startPath, { log: false });
        this.getToThatState(this.getStateByRestore.bind(this), {
          ...this.defaultNavigateOptions,
          log: false,
        });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then((elmModel) => {
          this.elmModel = elmModel;
          consolePropsSetter({ "Elm Model": elmModel });
        });
        // When restoring in the future we want to be restoring this local storage here
        this.localStorage = localStorage;
        cy.clearLocalStorage();
      }
    );
  }
  private getStateByRestore(key: Keys): void {
    if (this.otherCaches === undefined) {
      throw new Error("otherCaches not defined when it should be");
    }
    this.otherCaches[key].restoreState();
  }

  restoreState(
    options?: StateOptions & {
      navigateOptionsInCaseOfNavigateOverload?: ExtraNavigateOptions;
    }
  ): void {
    if (forceReloadAndNavigate) {
      cy.log("RELOADING INSTEAD OF RESTORE");

      if (options && "navigateOptionsInCaseOfNavigateOverload" in options) {
        const { navigateOptionsInCaseOfNavigateOverload, ...rest } = options;

        return this.reloadAndNavigateTo({
          ...rest,
          navigateOptions: navigateOptionsInCaseOfNavigateOverload,
        });
      }
      return this.reloadAndNavigateTo(options);
    }
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    if (options?.retainCurrentLocalStorage !== true && this.localStorage)
      cy.setLocalStorage(this.localStorage);
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }

  reloadAndNavigateTo(
    options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
  ): void {
    cy.withOverallNameLogged(
      {
        displayName: "NAVIGATING TO",
        message: this.name,
      },
      () => {
        if (options?.retainCurrentLocalStorage !== true && this.localStorage)
          cy.setLocalStorage(this.localStorage);
        cy.visit(this.startPath, {
          log: false,
          ...(options?.onBeforeLoad === undefined
            ? {}
            : { onBeforeLoad: options.onBeforeLoad }),
        });
        this.navigateFromStart(options);
      }
    );
  }

  private navigateFromStart(
    options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
  ): void {
    this.getToThatState(
      (key) => this.getStateByNavigate(key, options),
      options
    );
    this.waitForStateToAppear({ log: false });
  }

  private getStateByNavigate(
    key: Keys,
    options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
  ): void {
    if (this.otherCaches === undefined) {
      throw new Error("otherCaches not defined when it should be");
    }
    this.otherCaches[key].navigateFromStart(options);
  }

  setOtherCaches(
    caches: {
      [key in Keys]: StateCacheImplementation<Keys, ExtraNavigateOptions>;
    }
  ) {
    this.otherCaches = caches;
  }
}

export function buildStates<
  Keys extends string,
  ExtraNavigateOptions extends Record<string, unknown> = Record<string, never>
>(
  {
    startPath,
    localStorage,
    defaultNavigateOptions,
  }: {
    startPath: string;
    localStorage?: { [key: string]: unknown };
    defaultNavigateOptions: ExtraNavigateOptions;
  },
  states: {
    [key in Keys]: {
      name: string;
      getToThatState: (
        getState: (key: Keys) => void,
        options?: StateOptions & { navigateOptions?: ExtraNavigateOptions }
      ) => void;
      waitForStateToAppear: (options?: StateOptions) => void;
    };
  }
): { [key in Keys]: StateCache<ExtraNavigateOptions> } & {
  populateAll: (
    interceptArgs?: Parameters<typeof applyDefaultIntercepts>[0]
  ) => void;
} {
  if (startPath.includes(".")) {
    throw new Error(
      "buildStates argument has to be a path not a url. It had a `.` in it which we assumed mean you accidentally put a url"
    );
  }
  const pureStates = Cypress._.mapValues(
    states,
    (args) =>
      new StateCacheImplementation(
        args.name,
        startPath,
        args.getToThatState,
        defaultNavigateOptions,
        args.waitForStateToAppear,
        localStorage
      )
  );

  Cypress._.forEach(pureStates, (cache) => {
    cache.setOtherCaches(pureStates);
  });

  return {
    ...pureStates,
    populateAll: (interceptArgs) => {
      Cypress._.forEach(pureStates, (stateCache) =>
        stateCache.populateCache(interceptArgs)
      );
    },
  };
}
