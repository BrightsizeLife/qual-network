# IRR / Dimension Quality Analysis
library(tidyverse)
library(irr)
library(irrCAC)
library(jsonlite)
library(ggplot2)
source("R/00_utils.R")
ensure_dirs()

# Check for tagged_long.csv
if (!file.exists("data/tagged_long.csv")) {
  cat("WARNING: data/tagged_long.csv not found. Skipping IRR.\n")
  quit(save="no")
}

# Load tagging data
tagged <- readr::read_csv("data/tagged_long.csv", show_col_types=FALSE)
cat("Loaded", nrow(tagged), "tagging records\n")

# Get unique dimensions
dimensions <- unique(tagged$dimension)
cat("Computing IRR for", length(dimensions), "dimensions\n")

# Compute IRR metrics per dimension
irr_results <- list()

for (dim in dimensions) {
  dim_data <- tagged %>% filter(dimension == dim)

  # Pivot to wide: rows=entities, cols=raters
  wide <- dim_data %>%
    pivot_wider(names_from=rater_type, values_from=code, id_cols=entity) %>%
    select(-entity)

  # Convert to numeric matrix
  mat <- as.matrix(wide)
  mat <- apply(mat, 2, as.numeric)

  n_raters <- ncol(mat)

  # Compute metrics
  kripp_alpha <- NA
  fleiss_kappa <- NA
  cohen_kappa <- NA
  gwet_ac1 <- NA

  tryCatch({
    # Krippendorff's alpha (ordinal)
    kripp_alpha <- irrCAC::krippen.alpha.raw(mat, weights="ordinal")$est$coefficient_value
  }, error = function(e) {})

  tryCatch({
    # Fleiss' kappa
    fleiss_kappa <- irr::kappam.fleiss(mat, detail=FALSE)$value
  }, error = function(e) {})

  if (n_raters == 2) {
    tryCatch({
      # Cohen's kappa for 2 raters
      cohen_kappa <- irr::kappa2(mat, weight="squared")$value
    }, error = function(e) {})
  }

  tryCatch({
    # Gwet's AC1
    gwet_ac1 <- irrCAC::gwet.ac1.raw(mat)$est$coefficient_value
  }, error = function(e) {})

  irr_results[[dim]] <- list(
    dimension = dim,
    krippendorff_alpha = kripp_alpha,
    fleiss_kappa = fleiss_kappa,
    cohen_kappa = cohen_kappa,
    gwet_ac1 = gwet_ac1
  )
}

# Convert to dataframe
irr_df <- bind_rows(irr_results)

# Save JSON
write_json(irr_df, stamp("models/irr_summary", "model", "json"), auto_unbox=TRUE, pretty=TRUE)
cat("Saved IRR summary\n")

# Plot available metric (use fleiss_kappa if krippendorff missing)
metric_col <- if ("krippendorff_alpha" %in% names(irr_df)) "krippendorff_alpha" else "fleiss_kappa"
irr_df <- irr_df %>%
  mutate(metric_val = as.numeric(.data[[metric_col]])) %>%
  arrange(desc(metric_val))

g <- ggplot(irr_df, aes(x=reorder(dimension, metric_val), y=metric_val)) +
  geom_col(fill="steelblue") +
  geom_hline(yintercept=0.50, linetype="dashed", color="red") +
  coord_flip() +
  labs(x="Dimension", y=paste("IRR:", metric_col),
       title=paste("IRR:", metric_col, "by Dimension"),
       subtitle="Red line: 0.50 (needs refinement threshold)") +
  theme_minimal()

ggsave(stamp("plots/irr_kripp_alpha", "plot", "png"), g, width=8, height=10, dpi=150)
cat("Saved IRR plot\n")

# Report low-quality dimensions
low_alpha <- irr_df %>% filter(metric_val < 0.50)
if (nrow(low_alpha) > 0) {
  cat("\nDimensions needing specification refinement (α < 0.50):\n")
  cat(paste("-", low_alpha$dimension, collapse="\n"), "\n")
} else {
  cat("\nAll dimensions have α ≥ 0.50\n")
}

cat("IRR analysis complete.\n")
