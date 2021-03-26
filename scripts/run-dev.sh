#!/bin/bash

set -euo pipefail

elm-live src/Main.elm --port 4000 --pushstate --no-reload --dir public -- --debug --output public/main.js
