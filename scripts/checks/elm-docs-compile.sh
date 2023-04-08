#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd "${ROOT_DIRECTORY}"

# It seems like sometimes it fails on first try and succeeds on second for some reason?
# Or at the very least it seems to fail with bad error message on first try and then good one
# on second. Either way, it can be a good idea to retry
if ! ./node_modules/.bin/elm-doc-preview -o /dev/null; then
    echo "RETRYING AFTER INITIAL MAYBE FALSE NEGATIVE FAILURE";
    ./node_modules/.bin/elm-doc-preview -o /dev/null;
fi;
