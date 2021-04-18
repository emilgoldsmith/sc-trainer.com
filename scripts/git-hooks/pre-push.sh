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
run_check "No linting problems" "Elm analyse found linting issues" ./elm-analyse.sh
run_check "No formatting issues" "Formatting issues found" ./elm-format.sh
./elm-verify-examples.sh
run_check "elm-verify-examples are up to date" "You seem to have forgotten to update the elm-verify-examples. They are now up to date. Check them in, commit and try pushing again" check_for_uncommitted_changes
run_check "Unit Tests Passed" "Unit Tests Failed" ./elm-test.sh
