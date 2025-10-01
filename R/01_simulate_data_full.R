# Generates realistic synthetic data with time, location, source + 100 dims
# Plus tagged_long.csv for IRR analysis
library(tidyverse)
library(mvtnorm)
source("R/00_utils.R")
ensure_dirs()

set.seed(42)
n <- 1000
p <- 100
dims <- paste0("dim_", 1:p)

# === WIDE DATA WITH METADATA ===
# Generate time: spread over 12 months in 2024
start_date <- as.Date("2024-01-01")
time_vals <- sample(seq(start_date, by="day", length.out=365), n, replace=TRUE)

# Location: 5 cities
locations <- sample(c("NYC", "SF", "CHI", "ATL", "SEA"), n, replace=TRUE)

# Source: qual, forum, social (realistic proportions)
sources <- sample(c("qual", "forum", "social"), n, replace=TRUE,
                  prob=c(0.3, 0.4, 0.3))

# Build correlation matrix with structured blocks
Sigma <- diag(p)

# Add 4 latent blocks (communalities)
block_sizes <- sample(2:4, size=4, replace=TRUE)
start <- 1
for (b in seq_along(block_sizes)) {
  size <- block_sizes[b]
  end <- min(start + size - 1, p)
  idx <- start:end
  if (length(idx) > 1) {
    r <- runif(1, 0.4, 0.8)
    Sigma[idx, idx] <- r
    diag(Sigma)[idx] <- 1
  }
  start <- end + sample(3:8, 1)
  if (start > p) break
}

# Add random pairwise correlations
for (k in 1:(p*1.5)) {
  i <- sample(1:p, 1); j <- sample(setdiff(1:p, i), 1)
  r <- runif(1, -0.7, 0.9)
  Sigma[i, j] <- r
  Sigma[j, i] <- r
}

# Make positive semi-definite
nearPD <- function(M) {
  EV <- eigen((M + t(M))/2)
  V <- EV$vectors; D <- pmax(EV$values, 1e-6)
  V %*% diag(D) %*% t(V)
}
Sigma <- nearPD(Sigma)

# Generate multivariate normal
X <- rmvnorm(n, sigma = Sigma) %>% as.data.frame()
names(X) <- dims

# Combine metadata + dims
df <- tibble(
  entity = sprintf("E_%04d", 1:n),
  time = format(time_vals, "%Y-%m-%d"),
  location = locations,
  source = sources
) %>% bind_cols(X)

# Save wide data
outfile <- stamp("data/synthetic_qual_net", "model", "csv")
write_csv(df, outfile)
cat("Wrote wide data:", outfile, "\n")

# === TAGGED_LONG for IRR ===
# Simulate human + 2 AI raters tagging a subset of 15 dimensions on 0-3 scale
# Pick 15 representative dims
set.seed(43)
tagged_dims <- sample(dims, 15)
sample_entities <- sample(df$entity, 200)  # tag 200 entities

# Ground truth with some noise
gt_scores <- df %>%
  filter(entity %in% sample_entities) %>%
  select(entity, all_of(tagged_dims)) %>%
  pivot_longer(-entity, names_to="dimension", values_to="raw_score") %>%
  mutate(
    # Map continuous to ordinal 0-3
    true_code = cut(raw_score, breaks=c(-Inf, -0.5, 0, 0.5, Inf), labels=0:3, right=FALSE)
  )

# Human rater: high agreement with ground truth (~80%)
human_tags <- gt_scores %>%
  mutate(
    rater_type = "human",
    code = if_else(runif(n()) < 0.80, as.character(true_code),
                   sample(c("0","1","2","3"), n(), replace=TRUE))
  ) %>%
  select(entity, rater_type, dimension, code)

# AI_1: good agreement (~75%)
ai1_tags <- gt_scores %>%
  mutate(
    rater_type = "ai_1",
    code = if_else(runif(n()) < 0.75, as.character(true_code),
                   sample(c("0","1","2","3"), n(), replace=TRUE))
  ) %>%
  select(entity, rater_type, dimension, code)

# AI_2: moderate agreement (~65%)
ai2_tags <- gt_scores %>%
  mutate(
    rater_type = "ai_2",
    code = if_else(runif(n()) < 0.65, as.character(true_code),
                   sample(c("0","1","2","3"), n(), replace=TRUE))
  ) %>%
  select(entity, rater_type, dimension, code)

tagged_long <- bind_rows(human_tags, ai1_tags, ai2_tags)

# Save IRR data
write_csv(tagged_long, "data/tagged_long.csv")
cat("Wrote IRR data: data/tagged_long.csv\n")

# === TAGGING GUIDELINES ===
guidelines <- "# Dimension Tagging Guidelines

## Scale (0-3)
- **0**: Absent / Not mentioned
- **1**: Briefly mentioned or implied
- **2**: Discussed with some detail
- **3**: Central theme, extensively discussed

## Tips
- Focus on explicit content; avoid over-inference.
- When in doubt between adjacent levels, round down.
- Consult examples in training materials.

## Edge Cases
- Sarcasm or negation: code the literal semantic content.
- Multiple mentions: aggregate to highest applicable level.
"

writeLines(guidelines, "data/tagging_guidelines.md")
cat("Wrote: data/tagging_guidelines.md\n")

cat("Full synthetic data generation complete.\n")
