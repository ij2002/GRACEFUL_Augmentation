#!/usr/bin/env bash
# Runs the wj cardinality type for all three held-out databases (basketball,
# consumer, carcinogenesis) sequentially, all on one GPU. est/act/dd are
# already done and recorded in results/baseline_cost_estimation.xlsx for all
# three DBs -- this just fills in the last missing piece.
#
# One job runs at a time (sequential), so there's no need to spread across
# GPUs -- everything is pinned to WJ_DEVICE below. Sequential also avoids
# racing on the shared baseline_cost_estimation.xlsx write.
#
# Usage:
#   tmux new -s all_wj
#   bash run_all_wj.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WJ_DEVICE="${WJ_DEVICE:-0}"  #? Which single GPU to run all three wj jobs on.

RUNS=(
    "basketball:$SCRIPT_DIR/run_code_1.sh"
    "consumer:$SCRIPT_DIR/run_code_gpu2_1.sh"
    "carcinogenesis:$SCRIPT_DIR/run_code_gpu2.sh"
)

declare -A exit_codes=()

for entry in "${RUNS[@]}"; do
    IFS=':' read -r label run_script <<< "$entry"
    echo "=== $(date) Starting wj for $label (cuda:$WJ_DEVICE) ==="
    CARDINALITY_TYPE=wj DEVICE="$WJ_DEVICE" bash "$run_script"
    exit_codes["$label"]="$?"
    echo "=== $(date) Finished wj for $label (exit ${exit_codes[$label]}) ==="
done

echo
echo "=== SUMMARY ==="
overall_exit_code=0
for entry in "${RUNS[@]}"; do
    label="${entry%%:*}"
    code="${exit_codes[$label]}"
    status="OK"
    if [[ "$code" -ne 0 ]]; then
        status="FAILED (exit $code)"
        overall_exit_code=1
    fi
    echo "  $label: $status"
done

exit "$overall_exit_code"
