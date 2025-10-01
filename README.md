# qual-network
Synthetic qual-like dataset (entities × 100 dims), PCA + Bayesian Network.

## Setup
In R:
```r
source("R/install_pkgs.R")
```

## Usage
- R scripts in /R
- Outputs:
  - models/: timestamped RDS and CSV with suffix `_YYYYmmdd_HHMMSS_model`
  - plots/: timestamped PNG with suffix `_YYYYmmdd_HHMMSS_plot`
- Run: `make all` (requires R packages: tidyverse, mvtnorm, bnlearn, igraph, ggraph, ggplot2)
