#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY

./scripts/build-html.js --target=development

elm-spa gen

elm make --output build/public/main.js src/Main.elm

NODE_SCRIPT='const fs = require("fs");
const originalScript = fs.readFileSync("./build/public/main.js", "utf-8");
const withFFunctionsReplaced = originalScript.replace(/var ([^=]+)( = F\d\([^f]+function)[^(]\(/gmi, `var $1$2 __$1( `);
const finalScript = withFFunctionsReplaced.replace(/(\sA\d\([\s]+)([^,]+)(,[\s]+)(function[^(]+)\(/gm, `$1$2$3$4___$2(`);
fs.writeFileSync("./build/public/main.js", finalScript, "utf-8");'

node -e "$NODE_SCRIPT"

RESET_COLOUR=$(tput sgr0)
RED=$(tput setaf 1)

echo
echo "${RED}NOTE:${RESET_COLOUR}"
echo "${RED}NOTE: THIS COMMAND RUNS REGEXES THAT MAKE A LOT OF ANONYMOUS FUNCTIONS NAMED FOR EASE OF USE WITH TOOLS LIKE CHROME PROFILER$RESET_COLOUR"
echo "${RED}NOTE: THIS COMMAND DOESN'T REBUILD AT ALL SO YOU HAVE TO RESTART THE COMMAND IF YOU MAKE ANY CODE CHANGES$RESET_COLOUR"
echo "${RED}NOTE:${RESET_COLOUR}"

npx serve --listen 4000 --no-clipboard --single build/public
