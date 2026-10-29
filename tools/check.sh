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
"$engine" --headless --path . --fixed-fps 60 --script tests/test_demon_bind.gd 2>&1 | tee work/demon-bind-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_red_cap.gd 2>&1 | tee work/red-cap-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_local_versus.gd 2>&1 | tee work/local-versus-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_red_transform.gd 2>&1 | tee work/red-transform-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_mana_guard.gd 2>&1 | tee work/mana-guard-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_gamepads.gd 2>&1 | tee work/gamepads-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_carrot_skills.gd 2>&1 | tee work/carrot-skills-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_controller_settings.gd 2>&1 | tee work/controller-settings-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_new_rules.gd 2>&1 | tee work/new-rules-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_muay_thai.gd 2>&1 | tee work/muay-thai-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_six_skills.gd 2>&1 | tee work/six-skills-check.log
"$engine" --headless --path . --fixed-fps 60 --script tests/test_contact_controls.gd 2>&1 | tee work/contact-controls-check.log
if rg -n '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FAIL )' work/contact-controls-check.log; then
  exit 1
fi
if rg -n '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FAIL )' work/six-skills-check.log; then
  exit 1
fi
if rg -n '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|FAIL )' work/import-check.log work/test-check.log work/sprite-trial-check.log work/vfx-check.log work/blink-check.log work/blink-vfx-check.log work/combat-combos-check.log work/combo-poses-check.log work/demon-bind-check.log work/red-cap-check.log work/local-versus-check.log work/red-transform-check.log work/mana-guard-check.log work/gamepads-check.log work/carrot-skills-check.log work/controller-settings-check.log work/new-rules-check.log work/muay-thai-check.log; then
  exit 1
fi
