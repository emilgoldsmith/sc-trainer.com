import { applyDefaultIntercepts } from "support/interceptors";
import {
  pllTrainerElements,
  pllTrainerStates,
} from "./pll-trainer/state-and-elements.helper";

describe("randomness", function () {
  it("is deterministic under test", function () {
    applyDefaultIntercepts();
    saveWrongStateTestCase("first");
    saveWrongStateTestCase("second");
    saveWrongStateTestCase("third");
    cy.wrap(undefined, { log: false }).should(() => {
      // eslint-disable-next-line no-invalid-this
      const candidates = [this.first, this.second, this.third];
      candidates.forEach((c) => expect(typeof c).to.equal("string"));
      for (let i = 0; i < candidates.length; i++) {
        for (let j = i + 1; j < candidates.length; j++) {
          expect(candidates[i]).to.equal(candidates[j]);
        }
      }
    });
  });
});

function saveWrongStateTestCase(alias: string) {
  pllTrainerStates.wrongPage.navigateTo();
  pllTrainerElements.wrongPage.testCaseName.get().invoke("text").as(alias);
}
