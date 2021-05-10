export const paths = {
  pllTrainer: "/",
  homePage1: "",
  homePage2: "/",
  homePage3: "/index.html",
};

export const urls = Cypress._.mapValues(
  paths,
  (path) => Cypress.config().baseUrl + path
);
