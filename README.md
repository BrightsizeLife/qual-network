# qual-network

**Reproducible pipeline** for qualitative, forum, and social data analysis with:
- AI-assisted dimension tagging + human reliability checks (IRR)
- Automated PCA component selection (Parallel Analysis, Elbow, CV)
- Bayesian Networks (static + time-lagged) for structure discovery
- State-space (Kalman) models for temporal dynamics
- Human-readable + AI-ingestible HTML reports

## Quick Start

### 1. Install dependencies
```r
source("R/install_pkgs.R")
```

Required packages: `tidyverse`, `mvtnorm`, `bnlearn`, `igraph`, `ggraph`, `psych`, `irr`, `irrCAC`, `KFAS`, `jsonlite`, `quarto`

### 2. Generate synthetic data (or use your own)
```bash
Rscript R/01_simulate_data_full.R
```

Creates:
- `data/synthetic_qual_net_*.csv` (wide: entity, time, location, source, dim_1..dim_100)
- `data/tagged_long.csv` (IRR: entity, rater_type, dimension, code)
- `data/tagging_guidelines.md`

### 3. Run full pipeline
```bash
make pipeline
```

Or run steps individually:
```bash
Rscript R/02_irr_analysis.R          # IRR metrics
Rscript R/04_pca_auto_k.R            # PCA with auto-k
Rscript R/05_bayesian_networks.R     # BN structure learning
Rscript R/06_state_space.R           # Kalman filtering
Rscript R/09_render_reports.R        # HTML reports
```

## Data Contracts

### Wide data (`data/*.csv`)
Required columns:
- `entity` (ID)
- `dim_1`, `dim_2`, ..., `dim_N` (numeric/ordinal dimensions)

Optional columns:
- `time` (ISO-8601 date or integer)
- `location` (string)
- `source` ∈ {qual, forum, social}

### IRR tagging data (`data/tagged_long.csv`)
Columns:
- `entity`, `rater_type` ∈ {human, ai_1, ai_2, ...}, `dimension`, `code` (ordinal 0–3)

## Outputs

### models/ (timestamped `*_YYYYmmdd_HHMMSS_model.*`)
- `irr_summary_*.json` — IRR metrics per dimension
- `pca_*.rds`, `pca_loadings_*.csv`, `pca_selection_*.json` — PCA models + diagnostics
- `bn_fit_static_*.rds`, `bn_edges_static_*.csv` — Static Bayesian Network
- `bn_cmi_triplets_*.json` — Mediation/moderation probes (conditional MI)
- `state_space_pcs_*.json`, `state_space_topdims_*.json` — Kalman smoothed states

### plots/ (timestamped `*_YYYYmmdd_HHMMSS_plot.png`)
- `irr_kripp_alpha_*.png` — IRR bar chart
- `pca_scree_auto_*.png` — Scree plot with selected k
- `pca_scores_pc1_pc2_*.png` — PC scores biplot
- `bn_static_*.png` — Static DAG
- `state_space_pc1_level_*.png` — PC1 temporal dynamics

### reports/
- `01_dimensions_quality.html` — Data snapshot, IRR metrics, low-quality dimensions
- `02_structure_models.html` — PCA diagnostics, BN DAGs, state-space plots

## Documentation

See **[README_SCOPE.md](README_SCOPE.md)** for project vision, roadmap, and success metrics.

## Key Design Principles

1. **Interpretability first** — Every output includes selection criteria and diagnostics
2. **Timestamped artifacts** — Reproducible; no overwrites
3. **Human + AI readable** — JSON metadata alongside models; HTML for humans
4. **Quality checks** — IRR metrics flag dimensions needing refinement (α < 0.50)
