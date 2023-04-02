#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd $ROOT_DIRECTORY

./node_modules/.bin/elm-format src --validate
