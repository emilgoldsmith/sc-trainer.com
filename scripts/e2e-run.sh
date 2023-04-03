#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY/end-to-end-tests

./node_modules/.bin/cypress verify || ./node_modules/.bin/cypress install

./node_modules/.bin/cypress run .
