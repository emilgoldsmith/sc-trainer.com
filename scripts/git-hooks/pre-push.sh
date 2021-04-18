#!/bin/bash

set -euo pipefail

CHECKS_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../checks

cd $CHECKS_DIRECTORY

(output=$(git status --porcelain) && [ -z "$output" ]) || (echo "You have uncommitted changes. Commit or git stash them and try pushing again" && exit 1)
elm make ../../src/Main.elm
./elm-analyse.sh
./elm-format.sh
./elm-verify-examples.sh
(output=$(git status --porcelain) && [ -z "$output" ]) || (echo "You seem to have forgotten to update the elm-verify-examples. Check them in, commit and try pushing again" && exit 1)
./elm-test.sh
