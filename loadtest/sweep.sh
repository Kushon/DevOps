#!/usr/bin/env bash
# Прогон серии шагов нагрузки для поиска максимума пользователей.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"

# users spawn runtime label
STEPS=(
  "100 20 60s s100"
  "300 50 60s s300"
  "600 80 60s s600"
  "1000 100 60s s1000"
)

for step in "${STEPS[@]}"; do
  read -r users spawn runtime label <<< "$step"
  echo "########## STEP $label (users=$users) ##########"
  bash "$DIR/run_step.sh" "$users" "$spawn" "$runtime" "$label"
  echo "cooldown 20s..."; sleep 20
done
echo "ALL DONE"
