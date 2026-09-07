#!/usr/bin/env bash

set -euo pipefail

launcher="$1"
packages="$2"
executable_fixture="$3"
mkdir -p "$(dirname "$launcher")" "$packages"
cp "$executable_fixture" "$packages/cli"
chmod +x "$packages/cli"
ln -s "$packages/cli" "$launcher"
