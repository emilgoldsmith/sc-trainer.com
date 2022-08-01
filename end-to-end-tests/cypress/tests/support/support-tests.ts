import {
  completePLLTestInMilliseconds,
  pllTrainerElements,
} from "e2e/pll-trainer/state-and-elements";
import { assertCubeMatchesAlias } from "support/assertions";
import { applyDefaultIntercepts } from "support/interceptors";
import { PLL, pllToPllLetters } from "support/pll";

// Taken from https://www.petermorlion.com/iterating-a-typescript-enum/
function enumKeys<
  O extends Record<string, unknown>,
  K extends keyof O = keyof O
>(obj: O): K[] {
  return Object.keys(obj).filter((k) => Number.isNaN(+k)) as K[];
}

describe("Support Tests", function () {
  beforeEach(function () {
    applyDefaultIntercepts();
  });

  describe("plls", function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    enumKeys(PLL).forEach((pllKey) =>
      it(`ensure our test pll algorithm for ${
        pllToPllLetters[PLL[pllKey]]
      } has the same AUFs as the default in the app`, function () {
        const pll = PLL[pllKey];
        type Aliases = {
          firstCube: string;
        };
        // Here we first run a test where the app's default algorithm is used
        // but in pick algorithm we provide our test's default algorithm
        completePLLTestInMilliseconds(500, pll, {
          aufs: [],
          correct: true,
          testRunningCallback: () =>
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "firstCube">("firstCube"),
        });

        // Here we then run it now with our test's default algorithm
        // and assert that it results in the same cube as with the app\s default
        completePLLTestInMilliseconds(500, pll, {
          aufs: [],
          correct: true,
          testRunningCallback: () =>
            assertCubeMatchesAlias<Aliases, "firstCube">(
              "firstCube",
              pllTrainerElements.testRunning.testCase
            ),
        });
      })
    );
  });
});
