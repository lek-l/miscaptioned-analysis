"""Miscaptioned: reproduce the analyst view from benchmark_summary.csv.
Sources: US Bureau of Labor Statistics, Current Population Survey, Table 11, 2025; BLS Occupational Employment and Wage Statistics, May 2023 (approximate medians).
Requires: pandas, numpy, scipy, statsmodels
"""
import numpy as np
import pandas as pd
from scipy import stats
from statsmodels.stats.proportion import proportion_confint

df = pd.read_csv("data/benchmark_summary.csv")
p0 = df["bls_female_pct"] / 100

# 1. Observed share and 95% Wilson interval
df["obs"] = df["female"] / df["gendered_n"]
lo, hi = proportion_confint(df["female"], df["gendered_n"], alpha=0.05, method="wilson")
df["ci_low"], df["ci_high"] = lo * 100, hi * 100

# 2. One-sample z-test against the BLS share, two-sided
se = np.sqrt(p0 * (1 - p0) / df["gendered_n"])
df["z"] = (df["obs"] - p0) / se
df["p"] = 2 * stats.norm.sf(df["z"].abs())

# 3. Effect size: Cohen's h
df["h"] = 2 * np.arcsin(np.sqrt(df["obs"])) - 2 * np.arcsin(np.sqrt(p0))

# 4. Skew score: mean absolute gap in percentage points
df["gap"] = df["obs"] * 100 - df["bls_female_pct"]
print("Skew score:", round(df["gap"].abs().mean(), 2))

# 5. Does the gap track pay? Pearson r between log wage and gap
w = df.dropna(subset=["median_wage_usd"])
r, pval = stats.pearsonr(np.log(w["median_wage_usd"]), w["gap"])
print(f"Wage correlation r={r:.3f} (p={pval:.3f}, n={len(w)})")

# 6. Counterfactual rows needed per job to reach the workforce share
f, m = df["female"], df["male"]
n = f + m
df["rows"] = np.where(df["obs"] < p0, np.ceil((p0 * n - f) / (1 - p0)), np.ceil(((1 - p0) * n - m) / p0))

print(df[["term", "obs", "ci_low", "ci_high", "bls_female_pct", "gap", "p", "h", "rows"]].round(3).to_string(index=False))
