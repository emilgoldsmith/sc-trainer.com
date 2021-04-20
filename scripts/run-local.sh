#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/..

cd $ROOT_DIRECTORY

elm-live src/Main.elm --port 4000 --pushstate --no-reload --dir public -- --output public/main.js
