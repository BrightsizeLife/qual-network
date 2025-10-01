---
title: "Structure Models Report"
output: html_document
---



## PCA: Automated Component Selection


```
## **Selected k**: 2 
## 
## **Candidates**:
## - Parallel Analysis: 41 
## - Elbow (2nd derivative): 2 
## - 5-fold CV: 20 
## 
## **Cumulative variance at k = 2 **: 0.058
```

### Scree Plot

![plot of chunk unnamed-chunk-2](../plots/pca_scree_auto_20251001_001201_plot.png)

### PC Scores (PC1 vs PC2)

![plot of chunk unnamed-chunk-3](../plots/pca_scores_pc1_pc2_20251001_001202_plot.png)

### Top Loadings


Table: Top 10 Loadings on PC1 (by absolute value)

|    PC1|    PC2|variable |
|------:|------:|:--------|
|  0.352| -0.061|dim_1    |
|  0.320|  0.064|dim_2    |
| -0.300|  0.043|dim_38   |
|  0.293| -0.147|dim_22   |
| -0.223|  0.023|dim_29   |
| -0.215|  0.037|dim_28   |
|  0.188| -0.048|dim_45   |
| -0.182| -0.059|dim_74   |
| -0.168|  0.035|dim_96   |
|  0.167|  0.278|dim_42   |

---

## Bayesian Networks

### Static DAG

![plot of chunk unnamed-chunk-5](../plots/bn_static_20251001_001234_plot.png)

### Time-Lagged DAG


```
## *(No time-lagged BN; 'time' column not present)*
```

### Top Conditional MI Triplets (Mediation/Moderation Probes)


Table: Top 20 Triplets by Conditional MI

|X      |Y      |Z      |      cmi| pvalue|
|:------|:------|:------|--------:|------:|
|dim_22 |dim_27 |dim_97 | 339.3780| 0.0000|
|dim_15 |dim_43 |dim_52 | 275.5895| 0.0000|
|dim_1  |dim_2  |dim_96 | 181.8462| 0.0000|
|dim_1  |dim_2  |dim_18 | 171.3233| 0.0000|
|dim_1  |dim_2  |dim_29 | 166.4074| 0.0000|
|dim_30 |dim_59 |dim_74 | 149.8568| 0.0000|
|dim_19 |dim_71 |dim_73 | 131.6046| 0.0000|
|dim_2  |dim_29 |dim_91 |  91.6639| 0.0000|
|dim_6  |dim_32 |dim_49 |  56.1420| 0.0000|
|dim_3  |dim_22 |dim_92 |  32.7344| 0.0011|
|dim_21 |dim_34 |dim_36 |  30.6233| 0.0022|
|dim_78 |dim_86 |dim_92 |  30.3751| 0.0025|
|dim_17 |dim_35 |dim_48 |  28.8233| 0.0042|
|dim_31 |dim_47 |dim_96 |  28.3979| 0.0048|
|dim_5  |dim_20 |dim_93 |  27.1204| 0.0074|
|dim_28 |dim_49 |dim_69 |  23.2975| 0.0253|
|dim_14 |dim_59 |dim_66 |  21.9273| 0.0383|
|dim_36 |dim_44 |dim_75 |  21.6402| 0.0418|
|dim_2  |dim_49 |dim_95 |  21.3677| 0.0452|
|dim_6  |dim_16 |dim_41 |  21.3107| 0.0460|

**Note on limitations**: These are heuristic structure-learning results. Causal claims require domain knowledge, experimental design, and sensitivity analysis.

---

## State-Space Models (Kalman Filter)

### PC1 Level Over Time

![plot of chunk unnamed-chunk-8](../plots/state_space_pc1_level_20251001_001307_plot.png)

**Interpretation notes**:

- The smoothed level shows the estimated latent state of PC1 over time.
- Positive slopes indicate upward trends; negative slopes indicate downward trends.
- These are local linear trends; non-stationarity may be present.

---
*Report generated: 2025-10-01 00:14:01.15309*
