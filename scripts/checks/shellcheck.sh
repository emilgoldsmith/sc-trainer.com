#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd "${ROOT_DIRECTORY}"

RESET_COLOUR=$(tput sgr0)
RED=$(tput setaf 1)

if ! shellcheck --help &> /dev/null; then
    echo "${RED}You do not have shellcheck installed. This can for example be installed with sudo apt install shellcheck${RESET_COLOUR}"
    exit 1
fi

shellcheck scripts/checks/*.sh scripts/*.sh scripts/git-hooks/* scripts/helpers/*.sh
