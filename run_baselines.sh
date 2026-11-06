#!/usr/bin/env bash
# Baseline-only driver for run_code.sh: leave-one-out training with
# AUGMENT=False, 50 epochs, over the 14 databases that are not excluded
# (basketball, carcinogenesis, baseball, fhnk, financial, employee).
#
# Jobs run SEQUENTIALLY on purpose, even across different GPU_UUID values,
# to avoid racing on results/baseline_cost_estimation.xlsx.
#
# Usage:
#   tmux new -s baselines
#   conda activate graceful
#   GPU_UUID=GPU-... bash run_baselines.sh      # or fill in GPU_UUID below
#
# Output marker: .baseline_run_start is touched at launch so that
# collect_baseline_results.sh can package only this run's outputs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="$SCRIPT_DIR/run_code.sh"

# UUID of the GPU assigned to you (`nvidia-smi -L`), per the lab server manual.
# Never a GPU index. Leave empty when running inside a Slurm allocation.
if [[ -z "${SLURM_JOB_ID:-}" ]]; then
    export GPU_UUID="${GPU_UUID:-GPU-a8c5cc08-4849-f3c5-994a-4d8f2904006f}"  # GPU 6
fi

# -----------------------------------------------------------------------
# Each entry: label (before first space) followed by VAR=value overrides
# for run_code.sh. Cardinality type is left at run_code.sh's default (est).
# -----------------------------------------------------------------------
JOBS=(
    "baseball     TEST_DB=baseball     AUGMENT=False EPOCHS=50"
    "airline      TEST_DB=airline      AUGMENT=False EPOCHS=50"
    "genome       TEST_DB=genome       AUGMENT=False EPOCHS=50"
    "movielens    TEST_DB=movielens    AUGMENT=False EPOCHS=50"
    "ssb          TEST_DB=ssb          AUGMENT=False EPOCHS=50"
    "walmart      TEST_DB=walmart      AUGMENT=False EPOCHS=50"
    "geneea       TEST_DB=geneea       AUGMENT=False EPOCHS=50"
    "accidents    TEST_DB=accidents    AUGMENT=False EPOCHS=50"    
    "credit       TEST_DB=credit       AUGMENT=False EPOCHS=50"
    "tournament   TEST_DB=tournament   AUGMENT=False EPOCHS=50"
    "seznam       TEST_DB=seznam       AUGMENT=False EPOCHS=50"
    "imdb         TEST_DB=imdb         AUGMENT=False EPOCHS=50"
    "hepatitis    TEST_DB=hepatitis    AUGMENT=False EPOCHS=50"
    "tpc_h        TEST_DB=tpc_h        AUGMENT=False EPOCHS=50"
)

# Marker used by collect_baseline_results.sh to find files written by this run.
touch "$SCRIPT_DIR/.baseline_run_start"

declare -A exit_codes=()

for job in "${JOBS[@]}"; do
    label="${job%% *}"
    overrides="${job#* }"
    echo "=== $(date) Starting $label ($overrides) ==="
    env $overrides bash "$RUN_SCRIPT"
    exit_codes["$label"]="$?"
    echo "=== $(date) Finished $label (exit ${exit_codes[$label]}) ==="
done

echo
echo "=== SUMMARY ==="
overall_exit_code=0
for job in "${JOBS[@]}"; do
    label="${job%% *}"
    code="${exit_codes[$label]}"
    status="OK"
    if [[ "$code" -ne 0 ]]; then
        status="FAILED (exit $code)"
        overall_exit_code=1
    fi
    echo "  $label: $status"
done

exit "$overall_exit_code"
