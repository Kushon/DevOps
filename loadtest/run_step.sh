#!/usr/bin/env bash
# Прогон одного шага нагрузки + сэмплирование потребления подов на пике.
# usage: run_step.sh <users> <spawn-rate> <run-time> [label]
set -u
USERS="${1:?users}"; SPAWN="${2:?spawn}"; RUNTIME="${3:?run-time e.g. 90s}"
LABEL="${4:-u${USERS}}"
DIR="$(cd "$(dirname "$0")" && pwd)"
NS="cat-api-ns"
TOPLOG="$DIR/top_${LABEL}.log"
: > "$TOPLOG"

# Фоновый сэмплер top каждые 3с на время прогона
(
  for _ in $(seq 1 200); do
    kubectl top pod -n "$NS" --no-headers 2>/dev/null >> "$TOPLOG"
    echo "---" >> "$TOPLOG"
    sleep 3
  done
) &
SAMPLER=$!

"$DIR/.venv/bin/locust" -f "$DIR/locustfile.py" --host http://localhost:8080 \
  --headless -u "$USERS" -r "$SPAWN" --run-time "$RUNTIME" \
  --csv "$DIR/results_${LABEL}" --only-summary 2>"$DIR/locust_${LABEL}.err" \
  | tee "$DIR/summary_${LABEL}.txt"

kill "$SAMPLER" 2>/dev/null

echo
echo "==== PEAK CONSUMPTION (${LABEL}) ===="
# back и postgres пиковые CPU(m) и MEM(Mi)
awk '/back-deployment/   {gsub(/m/,"",$2); gsub(/Mi/,"",$3); if($2+0>bc)bc=$2; if($3+0>bm)bm=$3}
     /postgres-statefulset/{gsub(/m/,"",$2); gsub(/Mi/,"",$3); if($2+0>pc)pc=$2; if($3+0>pm)pm=$3}
     END{printf "back     peak: cpu=%dm  mem=%dMi\n", bc, bm; printf "postgres peak: cpu=%dm  mem=%dMi\n", pc, pm}' "$TOPLOG"
echo "==== replicas now ===="
kubectl get deploy cat-api-back-deployment -n "$NS" --no-headers 2>/dev/null
