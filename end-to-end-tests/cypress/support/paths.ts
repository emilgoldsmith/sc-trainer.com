export const paths = {
  pllTrainer: "/",
  homePage1: "",
  homePage2: "/",
};

export const unexposedInternalPaths = {
  componentTests: {
    errorPopup: "/unexposed-internal-routes/component-tests/error-popup-test",
    inlineError: "/unexposed-internal-routes/component-tests/inline-error-test",
    notification:
      "/unexposed-internal-routes/component-tests/notification-test",
  },
};

const baseUrl = Cypress.config().baseUrl;
if (!baseUrl)
  throw new Error("baseUrl Cypress config options is expected to be set");

export const urls = Cypress._.mapValues(paths, (path) => baseUrl + path);
