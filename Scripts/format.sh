#!/usr/bin/env bash
set -euo pipefail

if command -v swift-format >/dev/null 2>&1; then
  swift-format format --in-place --recursive Sources Tests
else
  echo "swift-format not installed; skipping" >&2
fi
