#!/bin/bash

set -euo pipefail

$(dirname "${BASH_SOURCE[0]}")/checks/elm-test.sh --watch
