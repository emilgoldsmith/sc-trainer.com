#!/bin/bash

set -euo pipefail

cat elm.json

elm-spa build

mv public/dist/elm.js main.min.js

rm -rf public/dist
