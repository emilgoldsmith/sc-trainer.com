#!/bin/sh

set -euo pipefail

npx serve --single --listen tcp://0.0.0.0:$PORT public
