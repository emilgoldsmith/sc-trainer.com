#!/bin/bash

set -euo pipefail

E2E_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../../end-to-end-tests

cd $E2E_DIRECTORY

yarn run prettier --check cypress
