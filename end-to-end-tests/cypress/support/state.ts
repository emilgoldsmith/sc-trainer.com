import { performStandardIntercepts } from "./interceptors";

export type StateOptions = { log?: boolean };
export interface StateCache {
  populateCache(): void;
  restoreState(options?: StateOptions): void;
  navigateToState(): void;
}

class StateCacheImplementation implements StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  constructor(
    private name: string,
    private startPath: string,
    private getToThatState: (options?: StateOptions) => void,
    private waitForStateToAppear: (options?: StateOptions) => void
  ) {}

  populateCache(): void {
    performStandardIntercepts();
    cy.withOverallNameLogged(
      {
        displayName: "POPULATING CACHE FOR STATE",
        message: this.name,
      },
      (consolePropsSetter) => {
        cy.visit(this.startPath);
        this.getToThatState({ log: false });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then((elmModel) => {
          this.elmModel = elmModel;
          consolePropsSetter({ "Elm Model": elmModel });
        });
      }
    );
  }

  restoreState(options?: StateOptions): void {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }

  navigateToState() {
    cy.withOverallNameLogged(
      {
        displayName: "NAVIGATE TO",
        message: this.name,
      },
      () => {
        cy.visit(this.startPath);
        this.getToThatState({ log: false });
        this.waitForStateToAppear({ log: false });
      }
    );
  }
}

export function buildStates<Keys extends string>(
  startPath: string,
  states: {
    [key in Keys]: {
      name: string;
      getToThatState: (options?: StateOptions) => void;
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
  return {
    ...pureStates,
    populateAll: () => {
      Cypress._.forEach(pureStates, (stateCache) => stateCache.populateCache());
    },
  };
}
