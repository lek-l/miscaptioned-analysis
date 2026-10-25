# Miscaptioned: Auditing Gender Skew in AI Training Captions

**Live interactive tool:** https://caption-bias-visualizer.lovable.app  
**Analysis Repository:** https://github.com/lek-l/miscaptioned-analysis

> Do the captions used to train image AI describe women and men in each job the way the real workforce looks? This project measures the gap against US Bureau of Labor Statistics data, tests statistical significance, evaluates heuristic robustness, and models cost-optimal remediation.

![Miscaptioned Overview](docs/images/01-hero-headline.png)

---

## Executive summary

| | |
| :--- | :--- |
| **Question** | Do AI image-caption datasets under- or over-represent women in specific jobs compared with the US workforce? |
| **Data** | Google Conceptual Captions (CC3M, 3.3M captions) vs US Bureau of Labor Statistics CPS Table 11 |
| **Scope** | 33 occupations with 20+ gendered captions (32,525 gendered caption matches) |
| **Headline** | Captions sit on average **19.2 points** away from each job's real share of women (17.8 on the 50,927-caption in-browser sample) |
| **Statistical Rigor** | **29 of 33** gaps are statistically significant (one-sample z-test, p < 0.05); **11** jobs show medium/large effect sizes (Cohen's h ≥ 0.5) |
| **Robustness** | A strict "within 5 words" proximity rule yields skew 18.3 vs 17.8; 2,284 ambiguous matches set aside; only 1 of 33 jobs (journalist) flips direction |
| **Remediation Impact** | Adding 1,979 targeted counterfactual captions (7.6% of full parity effort) cuts the skew in half. In-browser remediation reduces sample skew from **17.8 to 5.1 pts** |

![Audit Breakdown](docs/images/02-audit-breakdown.png)

**Representative findings:**
- **Writers:** 66.8% of US workforce are women, but only 16.8% of gendered "writer" captions describe a woman (-50.0 pt gap, p < 0.001, large effect).
- **CEOs:** 33.0% of US CEOs are women, but only 13.5% of CC3M CEO captions describe a woman (-19.5 pt gap).
- **Coaches:** 47.4% US workforce vs 8.0% captions (-39.4 pt gap, p < 0.001, large effect).
- **Mechanics:** 1.8% US workforce vs 36.0% captions (+34.2 pt gap, p < 0.001, large effect).

---

## Key findings and analytical insights

### 1. The skew is systematic, not random noise
Across the 33 benchmarked occupations, 29 exhibit representation gaps statistically distinguishable from chance (p < 0.05). Eleven occupations show a medium or large effect size (Cohen's h ≥ 0.5), indicating severe systematic bias rather than sample variance.

![Statistical Significance & Effect Sizes](docs/images/03-analyst-significance.png)

### 2. Diminishing returns in remediation: 7.6% effort removes 50% skew
Fixing jobs in order of marginal efficiency ("skew points removed per added counterfactual caption") produces an exponential decay curve:
- Rebalancing the **top 19 highest-leverage occupations requires only 1,979 added captions** (7.6% of the 26,193 required for complete parity across all 33 jobs) while eliminating **50% of total dataset skew** (19.2 → 9.5 pts).
- The remaining 50% of skew requires 24,214 additional captions across long-tail occupations.

![Cost of Fixing Efficiency Curve](docs/images/04-remediation-curve.png)

### 3. Occupational wage correlation is weak
Correlating each occupation's representation gap with log-transformed median annual earnings yields **r = 0.22 (p = 0.22, n = 33)**. Higher-paying occupations are not systematically more male-skewed in web-scraped captions; occupational stereotyping cuts across the pay spectrum. *(Note: Wage figures are approximate BLS national medians; see Limitations.)*

### 4. Verified deterministic remediation (17.8 → 5.1 pts)
The accompanying browser pipeline implements deterministic counterfactual data augmentation. It generates gender-flipped copies of minority-representation captions, runs strict grammar and pronoun agreement checks (e.g., *a/an*, subject-verb agreement), and verifies the new distribution against original audit rules.

![Remediation Verification](docs/images/05-verify-remediation.png)

---

## Methodology

```text
Raw Captions ──► Tokenize & Tag Gender ──► Match BLS Benchmarks ──► Calculate Skew & Stats ──► Model Remediation
```

- **Gender Tagging:** Captions containing exclusively female terms (*woman, girl, female, her, she, ...*) are labeled female; exclusively male terms (*man, boy, male, his, he, ...*) male; mixed or ungendered terms neutral.
- **Inclusion Threshold:** Requires ≥ 20 gendered occurrences to compute metrics; occupations under 150 instances receive a `LOW CONFIDENCE` flag.
- **Skew Score:** Mean absolute difference (in percentage points) between observed female caption proportion and the BLS Table 11 benchmark:
  $$\text{Skew} = \frac{1}{N} \sum_{i=1}^{N} |\%_{\text{caption}, i} - \%_{\text{workforce}, i}|$$
- **Confidence Intervals:** Wilson score 95% confidence intervals for observed proportions, robust to extreme probabilities and small sample sizes.
- **Hypothesis Testing:** One-sample two-tailed z-test of sample proportion against fixed BLS parameter.
- **Effect Size:** Cohen's $h = 2 \arcsin(\sqrt{p_1}) - 2 \arcsin(\sqrt{p_2})$. Thresholds: small (0.2), medium (0.5), large (0.8).
- **Heuristic Sensitivity:** A strict 5-token window constraint around occupation terms tests whether multi-person caption noise distorts scores. Skew moves from 17.8 to 18.3, confirming core findings are robust.

---

## Repository structure

```text
miscaptioned-analysis/
├── docs/
│   └── images/                        # Visual charts, UI screenshots, and efficiency curves
│       ├── 01-hero-headline.png
│       ├── 02-audit-breakdown.png
│       ├── 03-analyst-significance.png
│       ├── 04-remediation-curve.png
│       └── 05-verify-remediation.png
├── data/
│   └── benchmark_summary.csv          # 33 occupations: counts, CIs, BLS benchmarks, gaps, z, p, h, parity costs
├── notebooks/
│   └── miscaptioned_analysis.ipynb    # Reproducible walkthrough (pandas, SciPy, statsmodels, matplotlib)
├── scripts/
│   └── analysis_pipeline.py           # Automated end-to-end Python CLI pipeline
├── sql/
│   ├── 00_schema.sql                  # PostgreSQL DDL & CSV loading instructions
│   ├── 01_skew_audit.sql              # Window functions & CTEs calculating per-job gaps and rankings
│   ├── 02_remediation_priority.sql    # Cumulative cost curves and Pareto priority ordering
│   └── 03_significance_summary.sql    # Statistical categorization and effect-size aggregations
├── requirements.txt
└── README.md
```

---

## How to reproduce

### Python & Jupyter
```bash
git clone https://github.com/lek-l/miscaptioned-analysis.git
cd miscaptioned-analysis
pip install -r requirements.txt

# Run the full automated CLI pipeline
python scripts/analysis_pipeline.py

# Or explore interactively in Jupyter
jupyter notebook notebooks/miscaptioned_analysis.ipynb
```

### SQL (PostgreSQL)
1. Initialize schema and import data:
   ```bash
   psql -d <your_db> -f sql/00_schema.sql
   ```
2. Run remediation and prioritization analytics:
   ```bash
   psql -d <your_db> -f sql/02_remediation_priority.sql
   psql -d <your_db> -f sql/03_significance_summary.sql
   ```

---

## Limitations & considerations

- **Lexical Heuristics:** Keyword matching detects explicit lexical gender and cannot infer implicit gender; non-binary identities are unrepresented in binary BLS workforce records.
- **Sample Scope:** The interactive browser sample audits the first 500,000 CC3M rows containing job keywords (50,927 captions); full dataset metrics evaluate 3.3M captions.
- **Synthetic Rebalancing:** Counterfactual remediation adjusts caption frequencies to balance training signals; image pixels remain unchanged.
- **Wage Figures:** Annual median wages in the correlation model are estimates derived from BLS Occupational Employment Statistics.

---

## Author & acknowledgments

**Lekha** ([@lek-l](https://github.com/lek-l))  
Live App: [caption-bias-visualizer.lovable.app](https://caption-bias-visualizer.lovable.app)  
*Data sources: Google Conceptual Captions (CC3M), US Bureau of Labor Statistics CPS Table 11 (2024).*
