import { paths } from "support/paths";
import { pllTrainerElements } from "tests/pll-trainer/state-and-elements.helper";

describe("Main Smoke Test", function () {
  it("fetches the index without an error and displays the start page of the pll trainer", function () {
    // We run this in staging and production and we don't want it to count into the statistics and dirty them
    localStorage.setItem("plausible_ignore", "true");
    cy.visit(paths.pllTrainer);
    pllTrainerElements.startPage.container.assertShows();
  });
});
