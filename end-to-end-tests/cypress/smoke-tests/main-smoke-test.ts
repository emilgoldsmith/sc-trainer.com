import { paths } from "support/paths";
import { pllTrainerElements } from "tests/pll-trainer/state-and-elements.helper";

describe("Main Smoke Test", function () {
  it("fetches the index without an error and displays the start page of the pll trainer", function () {
    cy.visit(paths.pllTrainer);
    pllTrainerElements.startPage.assertAllShow();
  });
});
