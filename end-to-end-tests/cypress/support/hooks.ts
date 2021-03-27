/* eslint-disable mocha/no-top-level-hooks, mocha/no-hooks-for-single-case, mocha/no-sibling-hooks */

import { interceptAddingElmModelObserversAndModifiers } from "./elm-model-monkey-patching";

beforeEach(function () {
  interceptAddingElmModelObserversAndModifiers();
  ensureServerNotReloading();
});

function ensureServerNotReloading() {
  cy.intercept(Cypress.config().baseUrl + "/reload/reload.js", (_) => {
    throw new Error(
      `Reloading server most likely from ./scripts/run-hot.sh detected. \
This has been known to cause flaky tests in development, so we enforce \
using ./scripts/run-local.sh when developing with Cypress. It also \
just makes more sense as you won't have a Cypress test fail because of a \
recompile. ./scripts/run-local.sh still recompiles it just doesn't force \
a reload.
`
    );
  });
}
