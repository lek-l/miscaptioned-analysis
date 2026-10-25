# Miscaptioned: Auditing Gender Skew in AI Training Captions

**Live interactive tool:** https://caption-bias-visualizer.lovable.app

> Do the captions used to train image AI describe women and men in each job the way the real workforce looks? This project measures the gap, tests whether it is real, and works out the cheapest way to close it.

---

## Executive summary

| | |
| :--- | :--- |
| **Question** | Do AI image-caption datasets under- or over-represent women in specific jobs compared with the US workforce? |
| **Data** | Google Conceptual Captions (CC3M, 3.3M captions) vs US Bureau of Labor Statistics CPS Table 11 |
| **Scope** | 33 occupations with 20+ gendered captions (32,525 gendered caption matches) |
| **Headline** | Captions sit on average **19.2 points** away from each job's real share of women (17.8 on the 50,927-caption in-browser sample) |
| **Is it real?** | **29 of 33** gaps are statistically significant (p < 0.05); **11** jobs show a medium or large effect (Cohen's h) |
| **Is it noise?** | A stricter "within 5 words" matching rule gives a skew of 18.3 vs 17.8; only 1 job (journalist) changes direction |
| **Fix** | Counterfactual rebalancing brings the sample's skew from **17.8 to 5.1** |

**Example:** women are 66.8% of US writers, but only 16.8% of gendered "writer" captions describe a woman. Women are 33% of US CEOs, but 13.5% of CEO captions.

## Key findings and recommendations

1. **The skew is systematic, not random.** 29 of 33 occupations differ from the workforce beyond chance, mostly in the stereotyped direction (writer, coach, mechanic, secretary, surgeon, pilot).
2. **Closing half the gap is cheap.** Fixing jobs in order of "skew removed per added caption" halves the skew score (19.2 to 9.5) with **1,979 added captions, about 7.6%** of the 26,193 needed for full parity. Recommendation: rebalance the top 19 occupations first, then decide whether full parity is worth the remaining cost.
3. **Pay is only weakly linked.** The correlation between log median pay and the gap is r = 0.22 (n = 33), so higher-paid jobs are not clearly more skewed. *(Pay figures are approximate; see Limitations.)*
4. **Document the residual risk.** The tool generates a dataset card ("Bias, Risks, and Limitations") so downstream teams know what was measured and fixed.

## Methodology

```text
Captions  ->  Find occupation + gender words  ->  Compare with BLS share  ->  Skew score
```

- **Gender tag:** a caption with only female words is female, only male words is male, both or neither is neutral.
- **Minimum sample:** an occupation needs 20+ gendered captions to be scored; under 150 is flagged low confidence.
- **Skew score:** mean absolute gap, in percentage points, between the caption share of women and the BLS share.
- **Uncertainty:** Wilson 95% confidence interval for every caption share.
- **Significance:** one-sample z-test of the caption share against the BLS share.
- **Effect size:** Cohen's h, so a "significant" but tiny gap is not over-sold.
- **Remediation cost:** captions needed per job to reach the BLS share, ordered by gap removed per added caption.

### Robustness: co-occurrence is not coreference
Whole-caption matching can misattribute a person ("she is a fan of the CEO": she is not the CEO). A sensitivity test re-ran the audit counting only gender words within 5 words of the job: skew 18.3 vs 17.8, 2,284 matches set aside, one direction flip. The finding is not driven by multi-person captions.

## Repository structure

```text
miscaptioned-analysis/
├── data/
│   └── benchmark_summary.csv          # one row per occupation: counts, CI, BLS share, gap, z, p, h, rows to parity
├── notebooks/
│   └── miscaptioned_analysis.ipynb    # full analysis walkthrough (pandas, SciPy, statsmodels)
├── scripts/
│   └── analysis_pipeline.py           # same analysis as a single script
├── sql/
│   ├── 00_schema.sql                  # table layout + how to load the CSV
│   ├── 01_skew_audit.sql              # raw captions -> per-job gap, z-score, rank, skew score (CTEs + window functions)
│   ├── 02_remediation_priority.sql    # fix order and cumulative cost curve (running totals)
│   └── 03_significance_summary.sql    # significant gaps grouped by effect size
├── requirements.txt
└── README.md
```

## How to reproduce

```bash
git clone https://github.com/lek-l/miscaptioned-analysis.git
cd miscaptioned-analysis
pip install -r requirements.txt

python scripts/analysis_pipeline.py          # prints the per-job table
jupyter notebook notebooks/miscaptioned_analysis.ipynb
```

SQL (PostgreSQL): run `sql/00_schema.sql`, load the CSV with the `\copy` line inside it, then run `02` and `03`. `01` runs on raw caption tables.

## Limitations

- The in-browser sample is the first 500,000 CC3M rows filtered to job words, not a random sample.
- Keyword matching misses implicit gender and cannot describe non-binary people; BLS data is also binary.
- Pay figures are approximate medians entered by hand and should be checked against BLS before being quoted.
- Rebalancing uses gender-swapped copies of captions; it fixes counts, not image content.

## Tools

Python (pandas, SciPy, statsmodels), SQL (PostgreSQL), Jupyter. The interactive app is built with React and TypeScript and runs fully in the browser, so no data is uploaded.

## Author

**Lekha** · originally built for the SheBuilds hackathon, then extended into a full statistical analysis.
