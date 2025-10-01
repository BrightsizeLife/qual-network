# qual-network — Scope, Goals, Roadmap

## VISION

A reproducible pipeline that ingests qual, forums, and social data (time + location), applies AI-assisted dimension tagging with human reliability checks, and learns structure + temporal dynamics (PCA, BN, State-Space) to surface pathways, interactions, and time impacts.

---

## WHERE WE ARE (NOW)

- ✅ Repo scaffolding complete (`data/`, `models/`, `plots/`, `reports/`)
- ✅ Synthetic data generator with time, location, source metadata
- ✅ IRR analysis: Krippendorff's α, Fleiss' κ, Gwet AC1, Cohen's κ
- ✅ Automated PCA component selection via Parallel Analysis, Elbow, 5-fold CV
- ✅ Bayesian Networks: static structure learning + conditional MI probes
- ✅ State-space (Kalman) models: smoothed level/slope for PCs and top dimensions
- ✅ Two HTML reports: dimensions quality + structure models
- ✅ Timestamped outputs with JSON metadata for interpretability

---

## WHERE WE'RE GOING (NEXT 4–6 WEEKS)

### 1. Data Ingestion
- ✅ CSV contract set
- ✅ **social_pull v0** (HN + Reddit) with normalized `entity | source | meta_data | text` schema
- ⬜ Harmonize real inputs (qual transcripts, forums, social) with `{entity, time, location, source, dim_*}`
- ⬜ Add provenance fields (instrument version, annotator IDs)
- ⬜ X/LinkedIn connectors (gated by API keys)

### 2. Tagging & Quality Loop
- ✅ IRR metrics (α, κ, AC1)
- ⬜ Active guidance: highlight low-α dims and auto-insert TODOs in `tagging_guidelines.md`
- ⬜ Periodic "spec review" checklist and reruns (weekly cadence)

### 3. PCA Interpretability
- ✅ Auto-k via PA/Elbow/CV
- ⬜ Stability checks across time windows and sources
- ⬜ Factor labels: auto-generate candidate names from top-loading dims

### 4. BN Causal Hypotheses
- ✅ Static + time-lag BN
- ⬜ Interventional what-ifs (simulate node clamping)
- ⬜ Mediation candidates triage: promote top CMI triplets to human review queue

### 5. Time Dynamics
- ✅ Kalman level/slope for PCs
- ⬜ Regime-change detection and seasonality tests

### 6. Reporting for Humans + AI
- ✅ Two HTMLs
- ⬜ One "exec snapshot" page
- ⬜ JSON summaries for downstream agents

### 7. Ops & Reproducibility
- ✅ Timestamping
- ⬜ Data versioning notes
- ⬜ Minimal CPU/GPU requirements doc

---

## RISKS / GUARDRAILS

- **IRR < 0.50** indicates spec ambiguity → refine definitions, examples, and edge cases
- **BN edges** are associative under discretization; do not claim causality without design/assumptions
- **Time synthesized** when missing → clearly labeled and excluded from causal claims
- **Privacy**: ensure PII is removed or hashed; document retention windows
- **Social data ingestion**: use official APIs only; respect robots.txt and ToS; store only public content; consider PII in text fields

---

## SUCCESS METRICS

- ≥80% dimensions with **α ≥ 0.67** after two refinement cycles
- Stable PCA **k** across time windows (±1 component)
- Repeatable **BN motifs** across sources with clear narratives
- **Stakeholder satisfaction** on report usefulness (qual feedback)

---

## RUN BOOK (at a glance)

1. Put data in `data/` (wide CSV) and optional `tagged_long.csv`
2. Run `make pipeline` to regenerate models, plots, and reports (timestamped)
3. *Optional*: Run `make social_pull` to fetch public posts from HN/Reddit (see `docs/CONNECTORS.md` for auth setup)
4. Review `README_SCOPE.md` + `reports/*.html` weekly; prioritize the TODOs it surfaces

### Social Pull Data Contract

`data/social_pull_YYYYmmdd_HHMMSS_web_crawl.csv` schema:
- **entity**: Stable post ID (string)
- **source**: `hackernews`, `reddit`, `twitter`, `linkedin`
- **meta_data**: JSON string with `{url, author, created_utc, score, num_comments, reactions, origin}`
- **text**: Post title + " — " + body (raw, no truncation)

---

**This program prioritizes interpretability + repeatability over raw model complexity—every output must be understandable by both researchers and AI agents.**
