#!/bin/bash

set -euo pipefail

elm-live src/Main.elm --port 4000 --hot --pushstate -- --debug
