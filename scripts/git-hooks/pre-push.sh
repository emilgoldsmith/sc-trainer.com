#!/bin/bash

set -euo pipefail

CHECKS_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../checks

cd $CHECKS_DIRECTORY

function run_check() {
    local -a all_arguments=( "${@}" )

    ("${all_arguments[@]:2}" && echo $1) || (echo $2 && exit 1)
}

function check_for_uncommitted_changes() {
    output=$(git status --porcelain) && [ -z "$output" ]
}

run_check "No uncommitted changes" "You have uncommitted changes. Commit or git stash them and try pushing again" check_for_uncommitted_changes
run_check "Compiled Successfully" "Compilation Failed" elm make ../../src/Main.elm
rm --force index.html
./elm-analyse.sh
./elm-format.sh
./elm-verify-examples.sh
(output=$(git status --porcelain) && [ -z "$output" ]) || (echo "You seem to have forgotten to update the elm-verify-examples. Check them in, commit and try pushing again" && exit 1)
./elm-test.sh
