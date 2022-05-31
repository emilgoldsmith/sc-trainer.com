#!/bin/bash

set -euo pipefail

E2E_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../../end-to-end-tests

cd $E2E_DIRECTORY

yarn run prettier --ignore-path ../.gitignore --check cypress "../scripts/**/*.js" "../*.md" "../.github/**/*.yml" "*.json" "../*.json"
