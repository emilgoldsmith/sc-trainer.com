#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

E2E_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../../end-to-end-tests

cd $E2E_DIRECTORY

set -o xtrace

./node_modules/.bin/eslint --max-warnings 0 cypress --report-unused-disable-directives "$@"
