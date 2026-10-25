-- Miscaptioned: the same audit expressed in SQL (PostgreSQL).
-- Schema: captions(id, text, gender)  -- gender in ('female','male','neutral'), tagged by the word rule
--         caption_terms(caption_id, term)  -- one row per job word found in a caption
--         bls_benchmarks(term, occupation, female_pct)

WITH counts AS (
  SELECT ct.term,
         COUNT(*) FILTER (WHERE c.gender = 'female') AS female,
         COUNT(*) FILTER (WHERE c.gender = 'male')   AS male
  FROM caption_terms ct
  JOIN captions c ON c.id = ct.caption_id
  GROUP BY ct.term
),
joined AS (
  SELECT k.term, b.occupation, k.female, k.male,
         k.female + k.male                                   AS n,
         100.0 * k.female / NULLIF(k.female + k.male, 0)     AS observed_pct,
         b.female_pct                                        AS bls_pct
  FROM counts k
  JOIN bls_benchmarks b USING (term)
  WHERE k.female + k.male >= 20                              -- minimum sample rule
),
scored AS (
  SELECT *,
         observed_pct - bls_pct                                              AS gap_pts,
         (observed_pct / 100 - bls_pct / 100)
           / SQRT((bls_pct / 100) * (1 - bls_pct / 100) / n)                 AS z,
         RANK() OVER (ORDER BY ABS(observed_pct - bls_pct) DESC)             AS gap_rank
  FROM joined
)
SELECT term, occupation, n, ROUND(observed_pct, 1) AS observed_pct, bls_pct,
       ROUND(gap_pts, 1) AS gap_pts, ROUND(z, 2) AS z, gap_rank,
       ROUND(AVG(ABS(gap_pts)) OVER (), 2) AS skew_score
FROM scored
ORDER BY gap_rank;
