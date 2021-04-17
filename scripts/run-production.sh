#!/bin/bash

set -euo pipefail

echo $PORT

npx serve --single --listen tcp://0.0.0.0:$PORT public
