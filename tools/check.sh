#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work
touch work/.gdignore
engine="${GODOT_BIN:-godot}"
"$engine" --headless --path . --editor --import --quit 2>&1 | tee work/import-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_training.gd 2>&1 | tee work/test-check.log
if rg -n '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FAIL )' work/import-check.log work/test-check.log; then
  exit 1
fi
