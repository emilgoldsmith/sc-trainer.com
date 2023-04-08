#!/bin/sh

set -eu

############################################################
# In order for this script to work place everything in the
# top level public folder, and build-html will take care of
# hydrating the template and moving everything over into
# the build folder where everything will be served from.
# The build folder is also destroyed and recreated on every
# run so it is futile trying to change something there
############################################################

ROOT_DIRECTORY=$(dirname "$0")/..
cd "${ROOT_DIRECTORY}"

if [ $# -eq 0 ]; then
    ./scripts/build-html.js --target=production
elif [ $# -ne 1 ]; then
    echo >&2 "Exactly one or zero arguments expected"
    exit 1
elif [ "$1" = "--staging" ]; then
    ./scripts/build-html.js --target=staging
else
    echo >&2 "Only allowed option is --staging"
    exit 1
fi

./node_modules/.bin/serve --listen tcp://0.0.0.0:"${PORT:?}" --no-clipboard --single build/public
