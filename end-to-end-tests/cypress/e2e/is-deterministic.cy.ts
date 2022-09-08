import { applyDefaultIntercepts } from "support/interceptors";
import {
  completePLLTestInMilliseconds,
  pllTrainerElements,
} from "./pll-trainer/state-and-elements";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";

type Aliases = { first: string; second: string; third: string };
describe("randomness", function () {
  it("is deterministic under test", function () {
    applyDefaultIntercepts();
    cy.setLocalStorage(fullyPopulatedLocalStorage);
    saveWrongStateTestCase("first");
    saveWrongStateTestCase("second");
    saveWrongStateTestCase("third");
    cy.getAliases<Aliases>().should(({ first, second, third }) => {
      const candidates = [first, second, third];
      candidates.forEach((c) => expect(typeof c).to.equal("string"));
      for (let i = 0; i < candidates.length; i++) {
        for (let j = i + 1; j < candidates.length; j++) {
          expect(candidates[i]).to.equal(candidates[j]);
        }
      }
    });
  });
});

function saveWrongStateTestCase<Key extends keyof Aliases>(alias: Key) {
  completePLLTestInMilliseconds(7324, {
    correct: false,
    wrongType: "nearly there",
    startingState: "doNewVisit",
    endingState: "wrongPage",
  });
  pllTrainerElements.wrongPage.testCaseName
    .get()
    .invoke("text")
    // Just give up on typing here even though it sucks but we know
    // all the values of the Aliases object are the same so
    // there isn't a real danger at least at the time of writing.
    // it just seems like there isn't a better option when extracting
    // alias saving out to a function like this
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .setAlias<Aliases, Key>(alias as any);
}
