export const paths = {
  pllTrainer: "/",
  homePage1: "",
  homePage2: "/",
};

export const unexposedInternalPaths = {
  componentTests: {
    errorPopup: "/unexposed-internal-routes/component-tests/error-popup-test",
    inlineError: "/unexposed-internal-routes/component-tests/inline-error-test",
  },
};

export const urls = Cypress._.mapValues(
  paths,
  (path) => Cypress.config().baseUrl + path
);
