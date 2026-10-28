#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p work
touch work/.gdignore
engine="${GODOT_BIN:-godot}"
"$engine" --headless --path . --editor --import --quit 2>&1 | tee work/import-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_training.gd 2>&1 | tee work/test-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_sprite_trial.gd 2>&1 | tee work/sprite-trial-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_vfx.gd 2>&1 | tee work/vfx-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_blink.gd 2>&1 | tee work/blink-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_blink_vfx.gd 2>&1 | tee work/blink-vfx-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_combat_combos.gd 2>&1 | tee work/combat-combos-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_combo_poses.gd 2>&1 | tee work/combo-poses-check.log
if rg -n '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FAIL )' work/import-check.log work/test-check.log work/sprite-trial-check.log work/vfx-check.log work/blink-check.log work/blink-vfx-check.log work/combat-combos-check.log work/combo-poses-check.log; then
  exit 1
fi
