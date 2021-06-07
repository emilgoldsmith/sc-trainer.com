import { applyBeforeEachIntercepts } from "./hooks";
import { performStandardIntercepts } from "./interceptors";

export type StateOptions = { log?: boolean };
export interface StateCache {
  populateCache(): void;
  restoreState(options?: StateOptions): void;
  navigateTo(options?: StateOptions): void;
}

class StateCacheImplementation<Keys extends string> implements StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  private otherCaches?: { [key in Keys]: StateCache };

  constructor(
    private name: string,
    private startPath: string,
    private getToThatState: (
      getState: (key: Keys) => void,
      options?: StateOptions
    ) => void,
    private waitForStateToAppear: (options?: StateOptions) => void
  ) {}

  populateCache(): void {
    applyBeforeEachIntercepts();
    cy.withOverallNameLogged(
      {
        displayName: "POPULATING CACHE FOR STATE",
        message: this.name,
      },
      (consolePropsSetter) => {
        cy.visit(this.startPath, { log: false });
        this.getToThatState(this.getStateByRestore.bind(this), { log: false });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then((elmModel) => {
          this.elmModel = elmModel;
          consolePropsSetter({ "Elm Model": elmModel });
        });
      }
    );
  }
  private getStateByRestore(key: Keys): void {
    if (this.otherCaches === undefined) {
      throw new Error("otherCaches not defined when it should be");
    }
    this.otherCaches[key].restoreState();
  }

  restoreState(options?: StateOptions): void {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }

  navigateTo(): void {
    cy.withOverallNameLogged(
      {
        displayName: "NAVIGATING TO",
        message: this.name,
      },
      () => {
        cy.visit(this.startPath, { log: false });
        this.getToThatState(this.getStateByNavigate.bind(this), { log: false });
        this.waitForStateToAppear({ log: false });
      }
    );
  }

  private getStateByNavigate(key: Keys): void {
    if (this.otherCaches === undefined) {
      throw new Error("otherCaches not defined when it should be");
    }
    this.otherCaches[key].navigateTo();
  }

  setOtherCaches(caches: { [key in Keys]: StateCache }) {
    this.otherCaches = caches;
  }
}

export function buildStates<Keys extends string>(
  startPath: string,
  states: {
    [key in Keys]: {
      name: string;
      getToThatState: (
        getState: (key: Keys) => void,
        options?: StateOptions
      ) => void;
      waitForStateToAppear: (options?: StateOptions) => void;
    };
  }
): { [key in Keys]: StateCache } & { populateAll: () => void } {
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
        args.waitForStateToAppear
      )
  );

  Cypress._.forEach(pureStates, (cache) => {
    cache.setOtherCaches(pureStates);
  });

  return {
    ...pureStates,
    populateAll: () => {
      Cypress._.forEach(pureStates, (stateCache) => stateCache.populateCache());
    },
  };
}
