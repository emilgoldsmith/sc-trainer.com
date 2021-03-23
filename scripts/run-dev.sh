#!/bin/bash

set -euo pipefail

elm-live src/Main.elm --port 4000 --pushstate --no-reload -- --debug
