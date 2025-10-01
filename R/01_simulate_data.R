# Generates a 1000x(1+100) data frame: entity + dim_1..dim_100
# Correlations: inject several correlated "blocks" (2–4 dims share communality),
# and random pairwise correlations in [-1,1] elsewhere.
library(tidyverse)
library(mvtnorm)
source("R/00_utils.R")
ensure_dirs()

set.seed(42)
n <- 1000
p <- 100
dims <- paste0("dim_", 1:p)

# Build a block-diagonal-ish correlation matrix with small random noise plus a few strong blocks
Sigma <- diag(p)

# Add 4 latent blocks with sizes 2–4 (communalities)
block_sizes <- sample(2:4, size=4, replace=TRUE)
start <- 1
for (b in seq_along(block_sizes)) {
  size <- block_sizes[b]
  end <- min(start + size - 1, p)
  idx <- start:end
  if (length(idx) > 1) {
    # within-block correlations between 0.4 and 0.8
    r <- runif(1, 0.4, 0.8)
    Sigma[idx, idx] <- r
    diag(Sigma)[idx] <- 1
  }
  start <- end + sample(3:8, 1)  # gap before next block
  if (start > p) break
}

# Sprinkle additional pairwise correlations (some neg, some pos)
for (k in 1:(p*1.5)) {
  i <- sample(1:p, 1); j <- sample(setdiff(1:p, i), 1)
  r <- runif(1, -0.7, 0.9)
  Sigma[i, j] <- r
  Sigma[j, i] <- r
}
# Make Sigma positive semi-definite-ish via nearPD approach:
nearPD <- function(M) {
  EV <- eigen((M + t(M))/2)
  V <- EV$vectors; D <- pmax(EV$values, 1e-6)
  V %*% diag(D) %*% t(V)
}
Sigma <- nearPD(Sigma)

X <- rmvnorm(n, sigma = Sigma) %>% as.data.frame()
names(X) <- dims

df <- tibble(entity = sprintf("E_%04d", 1:n)) %>% bind_cols(X)

# Save CSV
outfile <- stamp("data/synthetic_qual_net", "model", "csv")  # treat as model artifact too
write_csv(df, outfile)
cat("Wrote:", outfile, "\n")
