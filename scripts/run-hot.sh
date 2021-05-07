#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY

./scripts/build.js --target=development

elm-live src/Main.elm --port 4000 --pushstate --hot --dir build/public -- --output=build/public/main.js --debug
