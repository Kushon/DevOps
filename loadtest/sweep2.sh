#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
STEPS=("700 90 60s s700" "800 100 60s s800" "900 100 60s s900")
for step in "${STEPS[@]}"; do
  read -r users spawn runtime label <<< "$step"
  echo "########## STEP $label (users=$users) ##########"
  bash "$DIR/run_step.sh" "$users" "$spawn" "$runtime" "$label"
  echo "cooldown 20s..."; sleep 20
done
echo "ALL DONE"
