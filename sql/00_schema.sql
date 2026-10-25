-- Miscaptioned: table layout used by the SQL queries (PostgreSQL).
CREATE TABLE captions (
  id      BIGINT PRIMARY KEY,
  text    TEXT NOT NULL,
  gender  TEXT NOT NULL CHECK (gender IN ('female', 'male', 'neutral'))  -- tagged by the word rule
);

CREATE TABLE caption_terms (            -- one row per occupation word found in a caption
  caption_id BIGINT REFERENCES captions(id),
  term       TEXT NOT NULL,
  PRIMARY KEY (caption_id, term)
);

CREATE TABLE bls_benchmarks (           -- BLS CPS Table 11, women's share of each occupation
  term        TEXT PRIMARY KEY,
  occupation  TEXT NOT NULL,
  female_pct  NUMERIC(5,2) NOT NULL
);

-- Results table, loadable straight from data/benchmark_summary.csv:
CREATE TABLE benchmark_summary (
  term TEXT PRIMARY KEY, bls_occupation TEXT, female INT, male INT, gendered_n INT,
  observed_female_pct NUMERIC, ci95_low NUMERIC, ci95_high NUMERIC, bls_female_pct NUMERIC,
  gap_pts NUMERIC, z NUMERIC, p_value DOUBLE PRECISION, cohens_h NUMERIC, effect TEXT,
  median_wage_usd NUMERIC, rows_to_parity INT, low_confidence BOOLEAN
);
-- \copy benchmark_summary FROM 'data/benchmark_summary.csv' CSV HEADER
