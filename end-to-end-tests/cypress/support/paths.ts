export const paths = {
  pllTrainer: "/",
  homePage1: "",
  homePage2: "/",
};

export const urls = Cypress._.mapValues(
  paths,
  (path) => Cypress.config().baseUrl + path
);
