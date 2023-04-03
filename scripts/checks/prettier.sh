#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

E2E_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../../end-to-end-tests

cd $E2E_DIRECTORY

set -o xtrace

./node_modules/.bin/prettier --check "$@" cypress forked_modules "../scripts/**/*.js" "../*.md" "../.github/**/*.yml" "*.json" "../*.json" "../review/*.json"
