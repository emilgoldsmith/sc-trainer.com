#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY

./scripts/build-html.js --target=development

elm-spa watch &

elm-live src/Main.elm --port 4000 --pushstate --no-reload --dir build/public -- --output build/public/main.js
