-- Miscaptioned: how many gaps are real, and how big (PostgreSQL).
SELECT effect,
       COUNT(*)                                          AS jobs,
       COUNT(*) FILTER (WHERE p_value < 0.05)            AS significant_at_5pct,
       ROUND(AVG(ABS(gap_pts)), 1)                       AS avg_abs_gap_pts,
       STRING_AGG(term, ', ' ORDER BY ABS(gap_pts) DESC) AS jobs_list
FROM benchmark_summary
GROUP BY effect
ORDER BY CASE effect WHEN 'large' THEN 1 WHEN 'medium' THEN 2 WHEN 'small' THEN 3 ELSE 4 END;
