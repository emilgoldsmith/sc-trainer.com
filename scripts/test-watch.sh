#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

"$(dirname "${BASH_SOURCE[0]}")"/checks/elm-test.sh --watch
