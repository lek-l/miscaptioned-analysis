-- Miscaptioned: which jobs to fix first for the least added data (PostgreSQL).
-- Runs on benchmark_summary (see 00_schema.sql). Mirrors the app's cost-of-fixing curve.
WITH ranked AS (
  SELECT term,
         ABS(gap_pts)                                           AS abs_gap,
         rows_to_parity,
         ABS(gap_pts) / GREATEST(rows_to_parity, 1)             AS gap_removed_per_row
  FROM benchmark_summary
),
ordered AS (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY gap_removed_per_row DESC)  AS fix_order,
         COUNT(*)     OVER ()                                   AS n_jobs,
         SUM(abs_gap) OVER ()                                   AS total_gap
  FROM ranked
),
cumulative AS (
  SELECT *,
         SUM(rows_to_parity) OVER (ORDER BY fix_order)          AS cumulative_rows,
         SUM(abs_gap)        OVER (ORDER BY fix_order)          AS gap_closed
  FROM ordered
)
SELECT fix_order, term, rows_to_parity, cumulative_rows,
       ROUND((total_gap - gap_closed) / n_jobs, 2)              AS skew_after_fix,
       ROUND(100.0 * gap_closed / total_gap, 1)                 AS pct_of_skew_removed
FROM cumulative
ORDER BY fix_order;
