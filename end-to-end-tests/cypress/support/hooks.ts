/* eslint-disable mocha/no-top-level-hooks, mocha/no-hooks-for-single-case */

import { performStandardIntercepts } from "./interceptors";

beforeEach(function () {
  localStorage.setItem("plausible_ignore", "true");
  performStandardIntercepts();
});
