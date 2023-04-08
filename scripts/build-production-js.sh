#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd "${ROOT_DIRECTORY}"

./node_modules/.bin/elm-spa build

mv public/dist/elm.js main.min.js

rm -rf public/dist
