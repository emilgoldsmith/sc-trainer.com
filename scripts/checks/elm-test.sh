#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd $ROOT_DIRECTORY

# Elm Test complains if there are source-directories listed in elm.json that don't exist
# so we create the .elm-spa ones in case they don't currently exist.
# They are gitignored so shouldn't be a problem to leave them lying around
mkdir -p .elm-spa/defaults .elm-spa/generated

./node_modules/.bin/elm-test "$@"
