"""Best augmented run per test_db: the run with the highest mean Q50 improvement over baseline,
restricted to cardinality_type "est" runs with augment-seq-regions True and where BOTH pull-up and push-down improve (> 0).
Runs with a blank augment-seq-regions predate the option and are excluded.
Improvement % = (baseline - augmented) / baseline * 100 (q-error, lower is better).
With --prefer-settings, qualifying runs using hybrid pooling, gated_residual refinement and SELU activation
are ranked first; a db only falls back to its best non-preferred run if it has no preferred qualifying run.
Without it (default) the highest mean improvement wins regardless of settings.
Either way, a db whose winner is not preferred also gets a second row (selection=best_preferred) with its
best qualifying preferred run, if one exists. Baseline is matched on (test_db, cardinality_type). Output columns match
results/best_experiments/best_q50_combined.csv.

Run with the graceful env: python scripts/best_runs_per_db.py [--by-card]
"""
import argparse
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
MODES = ["pull_up", "push_down"]
HP = ["augment-pooling", "augment-refinement", "augment-coarse-layers", "lambda-struct", "epochs", "augment-seq-regions", "activation"]
PREFERRED = {"augment-pooling": "hybrid", "augment-refinement": "gated_residual", "activation": "SELU"}

ap = argparse.ArgumentParser()
ap.add_argument("--augmented-xlsx", default=ROOT / "results/augmented_cost_estimation_combined.xlsx")
ap.add_argument("--baseline-xlsx", default=ROOT / "results/baseline_cost_estimation.xlsx")
ap.add_argument("--output", default=ROOT / "results/best_experiments/best_runs_per_db.csv")
ap.add_argument("--by-card", action="store_true", help="best per (db, cardinality_type) instead of per db")
ap.add_argument("--prefer-settings", action="store_true", help="rank hybrid/gated_residual/SELU runs first")
args = ap.parse_args()

a = pd.read_excel(args.augmented_xlsx)
b = pd.read_excel(args.baseline_xlsx)
cols = [f"{k}_q50_mean" for k in MODES]
m = a.merge(b[["test_db", "cardinality_type", *cols]], on=["test_db", "cardinality_type"], suffixes=("", "_base"))
for k, c in zip(MODES, cols):
    m[f"{k}_imp"] = (m[c + "_base"] - m[c]) / m[c + "_base"] * 100
m["both_avg"] = m[[f"{k}_imp" for k in MODES]].mean(axis=1)

ok = m[(m.cardinality_type == "est") & (m["augment-seq-regions"] == True) & (m.pull_up_imp > 0) & (m.push_down_imp > 0)]
keys = ["test_db", "cardinality_type"] if args.by_card else ["test_db"]
ok = ok.assign(preferred=np.all([ok[c] == v for c, v in PREFERRED.items()], axis=0))
order = ["preferred", "both_avg"] if args.prefer_settings else ["both_avg"]
ranked = ok.sort_values(order, ascending=False)
best = ranked.groupby(keys, sort=True).head(1).assign(selection="best")
alt = ok[ok.preferred].sort_values("both_avg", ascending=False).groupby(keys, sort=True).head(1)
alt = alt[~alt.set_index(keys).index.isin(best[best.preferred].set_index(keys).index)].assign(selection="best_preferred")
best = pd.concat([best, alt]).sort_values([*keys, "selection"])

out = best[["test_db", "cardinality_type", *cols, *[c + "_base" for c in cols],
            "pull_up_imp", "push_down_imp", "both_avg", *HP, "time_stamp", "preferred", "selection"]].round(3)
Path(args.output).parent.mkdir(parents=True, exist_ok=True)
out.to_csv(args.output, index=False)
print(out.drop(columns=[*cols, *[c + "_base" for c in cols]]).to_string(index=False))
skipped = sorted(set(m.test_db) - set(out.test_db))
print(f"\nwrote {args.output}\nno run with both improvements > 0: {skipped}")
