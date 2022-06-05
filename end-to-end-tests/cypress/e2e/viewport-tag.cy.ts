import { applyDefaultIntercepts } from "support/interceptors";
import { paths } from "support/paths";

describe("has correct viewport properties on url:", function () {
  // eslint-disable-next-line mocha/no-setup-in-describe
  const pathsToTest = Cypress._.values(paths);
  // eslint-disable-next-line mocha/no-setup-in-describe
  pathsToTest.forEach((path) =>
    it("'" + path + "'", function () {
      applyDefaultIntercepts();
      cy.visit(path);
      cy.get('head meta[name="viewport"][content]').then((metaElements) => {
        expect(metaElements).to.have.length(1);
        const content = metaElements.attr("content");
        if (content === undefined) {
          throw new Error("content of meta element is undefined");
        }
        const expected = [
          "width=device-width",
          "height=device-height",
          "initial-scale=1.0",
        ];
        const actual = content.split(",");
        // Asserting equal not caring about order
        expect(actual.length).to.equal(expected.length);
        expect(actual).to.have.members(expected);
        expect(expected).to.have.members(actual);
      });
    })
  );
});
