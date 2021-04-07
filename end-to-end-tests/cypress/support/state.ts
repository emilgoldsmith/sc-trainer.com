import { interceptAddingElmModelObserversAndModifiers } from "./elm-model-monkey-patching";

export class StateCache {
  private elmModel: Cypress.OurApplicationState | null = null;
  constructor(
    private name: string,
    private getToThatState: (options?: { log?: boolean }) => void,
    private waitForStateToAppear: (options?: { log?: boolean }) => void
  ) {}

  populateCache(): void {
    interceptAddingElmModelObserversAndModifiers();
    cy.withOverallNameLogged(
      {
        displayName: "POPULATING CACHE FOR STATE",
        message: this.name,
      },
      (consolePropsSetter) => {
        cy.visit("/");
        this.getToThatState({ log: false });
        this.waitForStateToAppear({ log: false });
        cy.getApplicationState(this.name, { log: false }).then((elmModel) => {
          this.elmModel = elmModel;
          consolePropsSetter({ "Elm Model": elmModel });
        });
      }
    );
  }

  restoreState(options?: { log?: boolean }): void {
    if (this.elmModel === null)
      throw new Error(
        `Attempted to restore the ${this.name} state before cache was populated`
      );
    cy.setApplicationState(this.elmModel, this.name, options);
    this.waitForStateToAppear(options);
  }
}
