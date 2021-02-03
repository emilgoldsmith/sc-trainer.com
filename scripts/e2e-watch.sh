#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY/end-to-end-tests

./node_modules/.bin/cypress open -P . || (./node_modules/.bin/cypress install && ./node_modules/.bin/cypress open -P .)
