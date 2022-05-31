import { assertCubeMatchesAlias } from "support/assertions";
import { applyDefaultIntercepts } from "support/interceptors";
import { PLL, pllToPllLetters } from "support/pll";
import {
  completePLLTestInMilliseconds,
  pllTrainerElements,
} from "tests/pll-trainer/state-and-elements.helper";

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
        completePLLTestInMilliseconds(500, pll, {
          aufs: [],
          correct: true,
          testRunningCallback: () =>
            pllTrainerElements.testRunning.testCase
              .getStringRepresentationOfCube()
              .setAlias<Aliases, "firstCube">("firstCube"),
        });

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
