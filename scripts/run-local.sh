#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY

./scripts/build-html.js --target=development

elm-spa gen

RESET_COLOUR=$(tput sgr0)
RED=$(tput setaf 1)
# The reason we don't use elm-spa watch & is because it rebuilds too often
# and can cause some slightly annoying issues as that rebuild triggers extra
# sometimes faulty rebuilds of elm-live if they aren't synced properly
# even though there aren't any real changes to the Elm SPA code.
echo
echo "${RED}NOTE:${RESET_COLOUR}"
echo "${RED}NOTE: Elm SPA generated files don't rebuild. Therefore a restart of the command is needed if files are removed/added/renamed in the Pages directory$RESET_COLOUR"
echo "${RED}NOTE:${RESET_COLOUR}"

elm-live src/Main.elm --port 4000 --no-reload --dir build/public -- --output build/public/main.js
