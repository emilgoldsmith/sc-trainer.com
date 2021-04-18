#!/bin/bash

set -euo pipefail

CHECKS_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../checks

cd $CHECKS_DIRECTORY

RESET_COLOUR=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)

function run_check() {
    local -a all_arguments=( "${@}" )

    echo -n "$YELLOW$1$RESET_COLOUR... "

    # Shell builtin that auto counts seconds, so we reset it to 0
    SECONDS=0
    (\
        "${all_arguments[@]:2}" > .temp_command_output 2>&1 \
        && echo "${GREEN}SUCCESS${YELLOW} ${SECONDS}s$RESET_COLOUR" \
        && rm .temp_command_output\
    ) || \
    (\
        echo -e "${RED}FAILED$RESET_COLOUR" \
        && echo \
        && echo "${RED}$2$RESET_COLOUR" \
        && echo \
        && ( \
            ( \
                [ -s .temp_command_output ] \
                && echo "Command Output Was As Follows:" \
                && echo \
                && cat .temp_command_output \
            ) || \
            ( \
                echo "No Command Output Detected"
            )
        ) \
        && echo \
        && echo "${YELLOW}Remember that if you need to push despite knowing CI will fail, you can use 'git push --no-verify'$RESET_COLOUR" \
        && echo \
        && rm .temp_command_output \
        && exit 1\
    )
}

function check_for_uncommitted_changes() {
    output=$(git status --porcelain) && [ -z "$output" ]
}

run_check \
    "Checking For Uncommitted Changes" \
    "You have uncommitted changes. Commit or 'git stash' them and try pushing again" \
    check_for_uncommitted_changes

run_check "Checking Compilation" "Compilation Failed" elm make ../../src/Main.elm --output=../../main.js
rm ../../main.js

run_check "Checking Linting" "Elm analyse found linting issues" ./elm-analyse.sh

run_check "Checking Code Formatting" "Formatting issues found" ./elm-format.sh

./elm-verify-examples.sh
run_check \
    "Checking Elm Verify Examples is up to date" \
    "You seem to have forgotten to update the elm-verify-examples. They are now up to date. Check them in, commit and try pushing again" \
    check_for_uncommitted_changes

run_check "Checking Unit Tests" "Unit Tests Failed" ./elm-test.sh
