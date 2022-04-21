import { interceptHtml, removeAnalyticsScripts } from "support/interceptors";
import { paths } from "support/paths";
import { pllTrainerElements } from "tests/pll-trainer/state-and-elements.helper";

describe("Main Smoke Test", function () {
  it("fetches the index without an error and displays the start page of the pll trainer", function () {
    // We run this in staging and production and we don't want it to count into the statistics and dirty them
    interceptHtml(removeAnalyticsScripts);
    cy.visit(paths.pllTrainer);
    pllTrainerElements.pickTargetParametersPage.container.assertShows();
  });
});
