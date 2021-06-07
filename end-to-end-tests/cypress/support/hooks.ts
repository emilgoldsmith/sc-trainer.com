/* eslint-disable mocha/no-top-level-hooks, mocha/no-exports, mocha/no-hooks-for-single-case */

import {
  addElmModelObserversAndModifiersToHtml,
  addElmModelObserversAndModifiersToJavascript,
  fixRandomnessSeedInJavascript,
} from "./elm-monkey-patching";
import { handleHtmlCypressModifications } from "./html-template-replacements";
import {
  ensureServerNotReloading,
  HtmlModifier,
  interceptHtml,
  interceptJavascript,
  JavascriptModifier,
} from "./interceptors";

const defaultHtmlModifiers: HtmlModifier[] = [
  addElmModelObserversAndModifiersToHtml,
  handleHtmlCypressModifications,
];

const defaultJavascriptModifiers: JavascriptModifier[] = [
  addElmModelObserversAndModifiersToJavascript,
  fixRandomnessSeedInJavascript,
];

beforeEach(function () {
  localStorage.setItem("plausible_ignore", "true");
  applyBeforeEachIntercepts();
});

export function applyBeforeEachIntercepts(): void {
  interceptHtml(...defaultHtmlModifiers);
  interceptJavascript(...defaultJavascriptModifiers);
  ensureServerNotReloading();
}

export function addHtmlModifier(modifier: HtmlModifier): void {
  defaultHtmlModifiers.push(modifier);
}
