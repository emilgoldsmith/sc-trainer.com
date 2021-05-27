#!/bin/sh

set -eu

ROOT_DIRECTORY=$(dirname $0)/..
cd $ROOT_DIRECTORY

if [ $# -eq 0 ]
then
    ./scripts/build-html.js --target=production
else if [ $# -ne 1 ]
then
    >&2 echo "Exactly one or zero arguments expected"
    exit 1
else if [ "$1" = "--staging" ]
then
    ./scripts/build-html.js --target=staging
else
    >&2 echo "Only allowed option is --staging"
    exit 1
fi fi fi

npx serve --listen tcp://0.0.0.0:$PORT --no-clipboard build/public
