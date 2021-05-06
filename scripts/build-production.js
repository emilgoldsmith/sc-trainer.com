#!/usr/local/bin/node

const options = process.argv.slice(2);

if (options.length > 1) {
  console.error(
    "Too many options provided, only accepted options are nothing, --staging, or --development"
  );
  process.exit(1);
}

const PRODUCTION = 0;
const STAGING = 1;
const DEVELOPMENT = 2;
let environment;
switch (options[0] || "") {
  case "--staging":
    environment = STAGING;
    break;
  case "--development":
    environment = DEVELOPMENT;
    break;
  case "":
    environment = PRODUCTION;
    break;
  default:
    console.error(
      "Invalid option: " +
        options[0] +
        "\nOnly allowed options are --staging and --development"
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

const stagingAndProductionFeatureFlags = JSON.parse(
  fs.readFileSync(FEATURE_FLAGS_PATH)
);
let localDevelopmentOverrides = null;
if (fs.existsSync(LOCAL_FLAG_OVERRIDE_PATH)) {
  localDevelopmentOverrides = JSON.parse(
    fs.readFileSync(LOCAL_FLAG_OVERRIDE_PATH)
  );
}
let featureFlagsToUse = null;
switch (environment) {
  case PRODUCTION:
    featureFlagsToUse = stagingAndProductionFeatureFlags.production;
    break;
  case STAGING:
    featureFlagsToUse = stagingAndProductionFeatureFlags.staging;
    break;
  case DEVELOPMENT:
    featureFlagsToUse =
      localDevelopmentOverrides || stagingAndProductionFeatureFlags.staging;
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
    { key: "FEATURE_FLAGS", value: featureFlagsToUse },
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
