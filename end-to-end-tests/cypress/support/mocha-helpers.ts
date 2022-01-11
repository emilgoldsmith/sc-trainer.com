/* eslint-disable mocha/no-exports */
/* eslint-disable mocha/no-hooks-for-single-case */
/* eslint-disable mocha/no-top-level-hooks */

import { setForceReloadAndNavigate } from "./state";

export function forceReloadAndNavigateIfDotOnlyIsUsed(): void {
  before(function () {
    let root: Mocha.Suite =
      // eslint-disable-next-line no-invalid-this
      this.test?.parent === undefined ? error() : this.test.parent;

    while (root.parent !== undefined) {
      root = root.parent;
    }
    if (root.hasOnly()) {
      setForceReloadAndNavigate();
    }
  });

  function error(): never {
    throw new Error("undefined parent suite");
  }
}
