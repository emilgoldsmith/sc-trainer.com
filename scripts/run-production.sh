#!/bin/sh

set -euo pipefail

npx serve --listen tcp://0.0.0.0:$PORT --no-clipboard public
