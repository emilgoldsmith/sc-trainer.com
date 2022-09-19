import { paths } from "support/paths";

describe("commands", function () {
  describe("visit", function () {
    it("waits for load event before allowing next commands", function () {
      // The reason we have this test is because we have previously forgotten to return the function result from visit and
      // that broke this guarantee. See https://github.com/cypress-io/cypress/issues/23108
      let load = false;
      cy.visit(paths.homePage1, { onLoad: () => (load = true) })
        .then(() => load)
        .should("be.true");
    });
  });
});
