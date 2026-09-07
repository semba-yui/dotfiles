#!/usr/bin/env bash

set -euo pipefail

if [[ ${1:-} == "--version" ]]; then
  printf 'fixture-cli 1.0.0\n'
else
  exit 1
fi
