import {
  addElmModelObserversAndModifiersToHtml,
  addElmModelObserversAndModifiersToJavascript,
  fixRandomnessSeedInJavascript,
} from "./elm-monkey-patching";
import { handleHtmlCypressModifications } from "./html-template-replacements";

export function interceptHtml(
  ...modifiers: ((previousHtml: { type: "html"; value: string }) => string)[]
): void {
  cy.intercept("*", (req) => {
    const expectsHtml =
      req.headers.accept && req.headers.accept.split(",").includes("text/html");
    if (!expectsHtml) return;

    req.reply((res) => {
      if (res.statusCode === 304) {
        throw new Error(
          "Got 304, which means we need to remove more headers from the request to force a fresh asset on every test"
        );
      }
      const body = res.body;
      if (typeof body !== "string") {
        throw new Error("Body response wasn't a string");
      }
      const modifiedHtml = modifiers.reduce(
        (curHtml, nextModifier) =>
          nextModifier({ type: "html", value: curHtml }),
        body
      );
      throw new Error(modifiedHtml);
    });
  });
}

export function interceptJavascript(
  ...modifiers: ((previousJavascript: {
    type: "js";
    value: string;
  }) => string)[]
): void {
  const jsPattern = Cypress.config().baseUrl + "/main.js";
  expect(Cypress.minimatch(Cypress.config().baseUrl + "/main.js", jsPattern)).to
    .be.true;
  cy.intercept(jsPattern, (req) => {
    // Delete caching headers so we always get fresh javascript to modify
    delete req.headers["if-modified-since"];
    delete req.headers["if-none-match"];
    req.reply((res) => {
      if (res.statusCode === 304) {
        throw new Error(
          "Got 304, which means we need to remove more headers from the request to force a fresh asset on every test"
        );
      }
      const body = res.body;
      if (typeof body !== "string") {
        throw new Error("Body response wasn't a string");
      }
      const modifiedJavascript = modifiers.reduce(
        (curJavascript, nextModifier) =>
          nextModifier({ type: "js", value: curJavascript }),
        body
      );
      res.send(modifiedJavascript);
    });
  });
}

export function performStandardIntercepts(): void {
  interceptHtml(
    addElmModelObserversAndModifiersToHtml,
    handleHtmlCypressModifications
  );
  interceptJavascript(
    addElmModelObserversAndModifiersToJavascript,
    fixRandomnessSeedInJavascript
  );
  ensureServerNotReloading();
}

function ensureServerNotReloading() {
  cy.intercept(Cypress.config().baseUrl + "/reload/reload.js", () => {
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
