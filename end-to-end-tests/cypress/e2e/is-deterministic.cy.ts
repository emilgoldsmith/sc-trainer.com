import { applyDefaultIntercepts } from "support/interceptors";
import {
  completePLLTestInMilliseconds,
  pllTrainerElements,
} from "./pll-trainer/elements-and-helper-functions";
import fullyPopulatedLocalStorage from "fixtures/local-storage/fully-populated.json";
import { fixRandomnessSeedInJavascript } from "support/elm-monkey-patching";

type Aliases = { first: string; second: string; third: string };
describe("randomness", function () {
  it("is deterministic under test when the fix seed interceptor is active", function () {
    applyDefaultIntercepts({
      extraJavascriptModifiers: [fixRandomnessSeedInJavascript],
    });
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
  cy.setLocalStorage(fullyPopulatedLocalStorage);
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
    // @ts-expect-error See above
    .setAlias<Aliases, Key>(alias);
}
