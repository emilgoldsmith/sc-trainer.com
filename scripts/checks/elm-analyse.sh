#!/bin/bash

set -euo pipefail

ROOT_DIRECTORY=$(dirname "${BASH_SOURCE[0]}")/../..

cd $ROOT_DIRECTORY

TEMPORARY_MODULE="src/Temporary.elm"

# Note this first one is a single arrow meaning overwrite, the next ones are double arrows which mean append

# Also note that this must be a pretty proper module as we don't want Elm Analyse to error on it in any way
# so we for example make sure there aren't any unused imports / variables etc.
echo "module Temporary exposing (temporary)" > $TEMPORARY_MODULE
echo "" >> $TEMPORARY_MODULE
echo "import ElmSpa.Page" >> $TEMPORARY_MODULE
echo "" >> $TEMPORARY_MODULE
echo "temporary : effect -> { init : model, update : msg -> model -> model, view : view } -> ElmSpa.Page.Page shared route effect view model msg" >> $TEMPORARY_MODULE
echo "temporary = ElmSpa.Page.sandbox" >> $TEMPORARY_MODULE

elm-analyse

rm src/Temporary.elm
