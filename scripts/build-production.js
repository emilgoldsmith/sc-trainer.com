#!/usr/local/bin/node

const options = process.argv.slice(2);

if (options.length > 1) {
  console.error(
    "Too many options provided, only accepted options are nothing, --staging, or --development"
  );
  process.exit(1);
}

const fs = require("fs");
const childProcess = require("child_process");
const path = require("path");

const BUILD_DIR = "build";
const PUBLIC_DIR = "public";

if (!fs.existsSync(PUBLIC_DIR)) {
  console.error(
    "the public directory with path `" +
      PUBLIC_DIR +
      "` did not exist and must exist at that path, maybe change your current directory"
  );
  process.exit(1);
}

childProcess.execSync(`rm -rf ${BUILD_DIR}`);
childProcess.execSync(`mkdir ${BUILD_DIR}`);
childProcess.execSync(`cp -R ${PUBLIC_DIR} ${BUILD_DIR}`);

const indexHtml = fs.readFileSync(
  path.join(BUILD_DIR, path.basename(PUBLIC_DIR), "index.html"),
  "utf-8"
);
console.log(indexHtml);
