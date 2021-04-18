#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd $ROOT_DIRECTORY

elm-format src --validate
