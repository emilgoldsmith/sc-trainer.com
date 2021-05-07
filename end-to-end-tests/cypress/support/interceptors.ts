import {
  addElmModelObserversAndModifiersToHtml,
  addElmModelObserversAndModifiersToJavascript,
} from "./elm-monkey-patching";
import { handleHtmlCypressModifications } from "./html-template-replacements";

export function interceptHtml(
  ...modifiers: ((previousHtml: string) => string)[]
): void {
  cy.intercept("*", (req) => {
    const expectsHtml =
      req.headers.accept && req.headers.accept.split(",").includes("text/html");
    if (!expectsHtml) return;

    req.reply((res) => {
      if (res.statusCode === 304) {
        // The server is saying the resource wasn't modified so we don't need to
        // modify either as the browser will know how to retrieve the previous version that we already will have modified
        return;
      }
      const modifiedHtml = modifiers.reduce(
        (curHtml, nextModifier) => nextModifier(curHtml),
        res.body
      );
      res.send(modifiedHtml);
    });
  });
}

export function interceptJavascript(
  ...modifiers: ((previousJavascript: string) => string)[]
): void {
  const jsPattern = Cypress.config().baseUrl + "/main.js";
  expect(Cypress.minimatch(Cypress.config().baseUrl + "/main.js", jsPattern)).to
    .be.true;
  cy.intercept(jsPattern, (req) => {
    req.reply((res) => {
      if (res.statusCode === 304) {
        // The server is saying main.js isn't modified so we don't need to
        // modify either as the browser will know how to retrieve the previous version
        return;
      }
      const modifiedJavascript = modifiers.reduce(
        (curJavascript, nextModifier) => nextModifier(curJavascript),
        res.body
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
  interceptJavascript(addElmModelObserversAndModifiersToJavascript);
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
