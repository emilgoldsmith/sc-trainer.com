import {
  addElmModelObserversAndModifiersToHtml,
  addElmModelObserversAndModifiersToJavascript,
  fixRandomnessSeedInJavascript,
} from "./elm-monkey-patching";
import { handleHtmlCypressModifications } from "./html-template-replacements";

export type HtmlModifier = (html: { type: "html"; value: string }) => string;

export type JavascriptModifier = (js: { type: "js"; value: string }) => string;

const baseUrl = (() => {
  const x = Cypress.config().baseUrl;
  if (!x)
    throw new Error("baseUrl Cypress config options is expected to be set");
  return x;
})();

export function interceptHtml(...modifiers: HtmlModifier[]): void {
  cy.intercept("GET", new RegExp(`^${baseUrl}`), (req) => {
    const acceptHeader = req.headers.accept;
    const acceptList =
      typeof acceptHeader === "string"
        ? acceptHeader.split(",")
        : typeof acceptHeader === "object"
        ? acceptHeader
        : acceptHeader;
    const expectsHtml = acceptList?.includes("text/html");
    if (!expectsHtml) return;

    req.reply((res) => {
      if (res.statusCode === 304) {
        throw new Error(
          "Got 304, which means we need to remove more headers from the request to force a fresh asset on every test"
        );
      }
      if (res.statusCode === 301 || res.statusCode === 302) {
        // Just ignore redirects, they'll be followed
        return;
      }
      const body: unknown = res.body;
      if (typeof body !== "string") {
        throw new Error("Body response wasn't a string");
      }
      const modifiedHtml = modifiers.reduce(
        (curHtml, nextModifier) =>
          nextModifier({ type: "html", value: curHtml }),
        body
      );
      res.send(modifiedHtml);
    });
  });
}

export function interceptJavascript(...modifiers: JavascriptModifier[]): void {
  const jsPattern = baseUrl + "/main.js";
  expect(Cypress.minimatch(baseUrl + "/main.js", jsPattern)).to.be.true;
  cy.intercept("GET", jsPattern, (req) => {
    // Delete caching headers so we always get fresh javascript to modify
    delete req.headers["if-modified-since"];
    delete req.headers["if-none-match"];
    req.reply((res) => {
      if (res.statusCode === 304) {
        throw new Error(
          "Got 304, which means we need to remove more headers from the request to force a fresh asset on every test"
        );
      }
      if (res.statusCode === 301 || res.statusCode === 302) {
        // Just ignore redirects, they'll be followed
        return;
      }
      const body: unknown = res.body;
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

export function ensureServerNotReloading(): void {
  cy.intercept(baseUrl + "/reload/reload.js", () => {
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

export function createFeatureFlagSetter(
  key: string,
  flagValue: boolean
): HtmlModifier {
  return function (prevHtml) {
    return prevHtml.value.replace(
      new RegExp(String.raw`("${key}":)(?:true|false)`),
      "$1" + JSON.stringify(flagValue)
    );
  };
}

export const removeAnalyticsScripts: HtmlModifier = (prevHtml) =>
  prevHtml.value
    .replace("\n", " ")
    .replace(
      /<script[^>]*src="[^"]*https:\/\/plausible\.io[^"]*"[^>]*>.*?<\/script>/,
      ""
    )
    .replace(/<script[^>]*src="[^"]*\/sentry.js"[^>]*>.*?<\/script>/, "")
    .replace(/\bSentry\.init\b/, "(() => {})")
    .replace(
      /\bSentry.captureMessage\b/,
      "((...args) => {throw new Error(JSON.stringify(args));})"
    )
    .replace(/\bnew Sentry[a-zA-Z.]+\b/, "(() => {return {};})");

const defaultHtmlModifiers: HtmlModifier[] = [
  addElmModelObserversAndModifiersToHtml,
  handleHtmlCypressModifications,
  removeAnalyticsScripts,
];

const defaultJavascriptModifiers: JavascriptModifier[] = [
  addElmModelObserversAndModifiersToJavascript,
  fixRandomnessSeedInJavascript,
];

export function applyDefaultIntercepts({
  extraHtmlModifiers,
  extraJavascriptModifiers,
}: {
  extraHtmlModifiers?: HtmlModifier[];
  extraJavascriptModifiers?: JavascriptModifier[];
} = {}): void {
  interceptHtml(...defaultHtmlModifiers, ...(extraHtmlModifiers ?? []));
  interceptJavascript(
    ...defaultJavascriptModifiers,
    ...(extraJavascriptModifiers ?? [])
  );
  ensureServerNotReloading();
}
