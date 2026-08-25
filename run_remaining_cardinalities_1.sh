#!/usr/bin/env bash
# Runs run_code_1.sh sequentially for the cardinality types NOT yet covered
# (act, dd, wj) for the held-out database currently configured inside
# run_code_1.sh (basketball). Skips est since that's already been run.
#
# Each cardinality type trains its own model (CARDINALITY_TYPE affects the
# training data, not just evaluation), and each gets its own row in
# results/baseline_cost_estimation.xlsx (upserted by test_db + cardinality_type),
# so results are appended rather than overwritten. Runs are sequential (not
# parallel) so there's no race on that shared xlsx file.
#
# Usage:
#   tmux new -s basketball_remaining_cardinalities
#   bash run_remaining_cardinalities_1.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_code_1.sh"

CARDINALITY_TYPES=(act dd wj)

declare -A exit_codes=()

for card_type in "${CARDINALITY_TYPES[@]}"; do
    echo "=== $(date) Starting cardinality_type=$card_type ==="
    CARDINALITY_TYPE="$card_type" bash "$RUN_SCRIPT"
    exit_codes["$card_type"]="$?"
    echo "=== $(date) Finished cardinality_type=$card_type (exit ${exit_codes[$card_type]}) ==="
done

echo
echo "=== SUMMARY ==="
overall_exit_code=0
for card_type in "${CARDINALITY_TYPES[@]}"; do
    code="${exit_codes[$card_type]}"
    status="OK"
    if [[ "$code" -ne 0 ]]; then
        status="FAILED (exit $code)"
        overall_exit_code=1
    fi
    echo "  $card_type: $status"
done

exit "$overall_exit_code"
