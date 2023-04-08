#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd "${ROOT_DIRECTORY}"

./node_modules/.bin/elm-verify-examples
