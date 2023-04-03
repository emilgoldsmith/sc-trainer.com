#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd "$ROOT_DIRECTORY"

TEMPORARY_MODULE="src/Temporary.elm"

cleanup() {
    rm "$TEMPORARY_MODULE"
}

function on_sigint() {
    cleanup
    exit 1
}

trap on_sigint SIGINT

### The reason for this is that CI detects elm-spa as an unused dependency when we haven't generated the elm-spa files
### using the CLI. We don't actually need to generate any elm-spa files for our linting job in CI so instead we just do
### this small hack of adding a temporary file that imports an elm-spa file.


# Note this first one is a single arrow meaning overwrite, the next ones are double arrows which mean append

# Also note that this must be a pretty proper module as we don't want Elm Analyse to error on it in any way
# so we for example make sure there aren't any unused imports / variables etc.
echo "module Temporary exposing (temporary)" > $TEMPORARY_MODULE
echo "" >> $TEMPORARY_MODULE
echo "import ElmSpa.Page" >> $TEMPORARY_MODULE
echo "" >> $TEMPORARY_MODULE
echo "temporary : effect -> { init : model, update : msg -> model -> model, view : view } -> ElmSpa.Page.Page shared route effect view model msg" >> $TEMPORARY_MODULE
echo "temporary = ElmSpa.Page.sandbox" >> $TEMPORARY_MODULE

./node_modules/.bin/elm-review "$@" src tests || (cleanup && exit 1)

cleanup

./node_modules/.bin/elm-review suppress --check-after-tests
