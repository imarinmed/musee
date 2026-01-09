#!/usr/bin/env bash
set -euo pipefail

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint
else
  echo "swiftlint not installed; skipping" >&2
fi

if command -v swift-format >/dev/null 2>&1; then
  swift-format lint --recursive Sources Tests
else
  echo "swift-format not installed; skipping" >&2
fi
