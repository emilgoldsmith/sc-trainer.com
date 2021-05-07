#!/usr/bin/env node

const options = process.argv.slice(2);

if (options.length !== 1 || typeof options[0] !== "string") {
  console.error(
    `\
Exactly one option that takes exactly one of the following three values was expected. ${options.length} options were found.

Accepted options are: --target=development, --target=staging or --target=production`
  );
  process.exit(1);
}

const PRODUCTION = 0;
const STAGING = 1;
const DEVELOPMENT = 2;
let environment;
switch (options[0].split("--target=")[1]) {
  case "development":
    environment = DEVELOPMENT;
    break;
  case "staging":
    environment = STAGING;
    break;
  case "production":
    environment = PRODUCTION;
    break;
  default:
    console.error(
      "Invalid option: " +
        options[0] +
        "\n\nOnly allowed options are --target=development, --target=staging or --target=production"
    );
    process.exit(1);
}

const fs = require("fs");
const childProcess = require("child_process");
const path = require("path");

const BUILD_DIR = "build";
const PUBLIC_DIR = "public";
const HTML_TEMPLATE_NAME = "index.template.html";
const FEATURE_FLAGS_PATH = path.join("config", "feature-flags.json");
const LOCAL_FLAG_OVERRIDE_PATH = path.join(
  "config",
  "local-feature-flags.json"
);

if (!fs.existsSync(PUBLIC_DIR)) {
  console.error(
    "the public directory with path `" +
      PUBLIC_DIR +
      "` did not exist and must exist at that path, maybe change your current directory"
  );
  process.exit(1);
}
if (!fs.existsSync(FEATURE_FLAGS_PATH)) {
  console.error(
    "The feature flags config file with path `" +
      FEATURE_FLAGS_PATH +
      "` did not exist and must exist at that path, maybe change your current directory"
  );
  process.exit(1);
}

childProcess.execSync(`rm -rf ${BUILD_DIR}`);
childProcess.execSync(`mkdir ${BUILD_DIR}`);
childProcess.execSync(`cp -R ${PUBLIC_DIR} ${BUILD_DIR}`);

const BUILT_PUBLIC_PATH = path.join(BUILD_DIR, path.basename(PUBLIC_DIR));

const indexHtmlTemplate = fs.readFileSync(
  path.join(BUILT_PUBLIC_PATH, HTML_TEMPLATE_NAME),
  "utf-8"
);

/**
 * @arg {any[]} a1
 * @arg {any[]} a2
 * @returns {boolean}
 */
function sameElements(a1, a2) {
  if (a1.length !== a2.length) return false;
  for (x of a1) {
    if (!a2.includes(x)) return false;
  }
  return true;
}

/**
 * @constant
 * @type {{staging: {[key: string]: boolean}; production: {[key: string]: boolean}}}
 */
const deploymentFlags = JSON.parse(fs.readFileSync(FEATURE_FLAGS_PATH));
if (
  !sameElements(
    Object.keys(deploymentFlags.production),
    Object.keys(deploymentFlags.staging)
  )
) {
  console.error(
    `Invalid feature flags. Staging and Production don't have same keys. Staging had keys ${JSON.stringify(
      Object.keys(deploymentFlags.staging)
    )} and production had ${JSON.stringify(
      Object.keys(deploymentFlags.production)
    )}`
  );
  process.exit(1);
}

/**
 * @constant
 * @type {{[key: string]: boolean} | null}
 */
let localDevelopmentOverrides = null;
if (fs.existsSync(LOCAL_FLAG_OVERRIDE_PATH)) {
  localDevelopmentOverrides = JSON.parse(
    fs.readFileSync(LOCAL_FLAG_OVERRIDE_PATH)
  );
  if (
    !sameElements(
      Object.keys(deploymentFlags.staging),
      Object.keys(localDevelopmentOverrides)
    )
  ) {
    console.error(
      `Invalid feature flags. Local development overrides didn't have same flags as deployment ones. Staging had keys ${JSON.stringify(
        Object.keys(deploymentFlags.staging)
      )} and local overrides had ${JSON.stringify(
        Object.keys(localDevelopmentOverrides)
      )}`
    );
    process.exit(1);
  }
}

let featureFlagsToUse = null;
switch (environment) {
  case PRODUCTION:
    featureFlagsToUse = deploymentFlags.production;
    break;
  case STAGING:
    featureFlagsToUse = deploymentFlags.staging;
    break;
  case DEVELOPMENT:
    featureFlagsToUse = localDevelopmentOverrides || deploymentFlags.staging;
    break;
  default:
    throw new Error(`Unexpected environment: ${environment}`);
}

/**
 * @param {{template: string, key: string, value: string}}
 * @returns {string}
 */
function replaceInTemplateForKey({ template, key, value }) {
  const startIdentifier = `/** REPLACED_WITH_${key}_START **/`;
  const endIdentifier = `/** REPLACED_WITH_${key}_END **/`;
  const startIndex = template.indexOf(startIdentifier);
  const endIndex = template.indexOf(endIdentifier) + endIdentifier.length;
  return (
    template.substring(0, startIndex) +
    JSON.stringify(value) +
    template.substring(endIndex)
  );
}

/**
 * @param {string} template
 * @param {{key: string, value: string}[]} replacements
 * @returns {string}
 */
function replaceMany(template, replacements) {
  return replacements.reduce(
    (currentTemplateState, { key: nextKey, value: nextValue }) =>
      replaceInTemplateForKey({
        template: currentTemplateState,
        key: nextKey,
        value: nextValue,
      }),
    template
  );
}

const builtIndexHtml = replaceMany(
  indexHtmlTemplate,

  [
    {
      key: "FEATURE_FLAGS",
      value: { placeholder: false, ...featureFlagsToUse },
    },
    {
      key: "SENTRY_ENABLE",
      value: environment === PRODUCTION || environment === STAGING,
    },
    {
      key: "SENTRY_ENVIRONMENT",
      value:
        { [PRODUCTION]: "production", [STAGING]: "staging" }[environment] ||
        undefined,
    },
  ]
);

childProcess.execSync(`rm ${path.join(BUILT_PUBLIC_PATH, HTML_TEMPLATE_NAME)}`);
fs.writeFileSync(path.join(BUILT_PUBLIC_PATH, "index.html"), builtIndexHtml);
