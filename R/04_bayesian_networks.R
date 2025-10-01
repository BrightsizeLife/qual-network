# Bayesian Networks: static + time-lagged + mediation/moderation probes
library(tidyverse)
library(bnlearn)
library(igraph)
library(ggraph)
library(jsonlite)
source("R/00_utils.R")
ensure_dirs()

# Load latest data
csvs <- list.files("data", pattern="\\.csv$", full.names=TRUE)
stopifnot(length(csvs) > 0)
csv <- csvs[which.max(file.mtime(csvs))]
df_full <- readr::read_csv(csv, show_col_types=FALSE)

# Check for time column
has_time <- "time" %in% colnames(df_full)

# Extract dims
df <- df_full %>% select(starts_with("dim_"))
p <- ncol(df)

# ===== STATIC BN =====
cat("Learning static BN...\n")
df_disc <- discretize(df, method="quantile", breaks=3)

bn_static <- hc(df_disc)
fit_static <- bn.fit(bn_static, df_disc)

saveRDS(fit_static, stamp("models/bn_fit_static", "model", "rds"))
edges_static <- as_tibble(arcs(bn_static), .name_repair="minimal")
if (nrow(edges_static) > 0) {
  colnames(edges_static) <- c("from", "to")
}
readr::write_csv(edges_static, stamp("models/bn_edges_static", "model", "csv"))

# Plot static DAG
if (nrow(edges_static) > 0) {
  g_static <- graph_from_data_frame(edges_static, directed=TRUE, vertices=tibble(name=colnames(df_disc)))
} else {
  g_static <- make_empty_graph(n=ncol(df_disc), directed=TRUE)
  V(g_static)$name <- colnames(df_disc)
}
p_static <- ggraph(g_static, layout="fr") +
  geom_edge_link(arrow = arrow(length = unit(2, "mm")), end_cap = circle(2, "mm"), alpha=.4) +
  geom_node_point(size=1.5, color="steelblue") +
  geom_node_text(aes(label=name), repel=TRUE, size=2.5) +
  ggtitle("Bayesian Network (static, hc)") +
  theme_void()
ggsave(stamp("plots/bn_static", "plot", "png"), p_static, width=10, height=8, dpi=150)

# ===== TIME-LAGGED BN (if time exists) =====
if (has_time) {
  cat("Learning time-lagged BN...\n")
  df_time <- df_full %>% select(time, starts_with("dim_"))
  df_time <- df_time %>% arrange(time)

  # Create lagged variables
  df_lagged <- df_time %>%
    mutate(across(starts_with("dim_"), ~lag(.x, 1), .names="{.col}_lag1"))
  df_lagged <- df_lagged %>% drop_na()

  # Select current + lagged dims
  df_two_slice <- df_lagged %>% select(starts_with("dim_"))

  df_two_disc <- discretize(df_two_slice, method="quantile", breaks=3)

  bn_time <- hc(df_two_disc)
  fit_time <- bn.fit(bn_time, df_two_disc)

  saveRDS(fit_time, stamp("models/bn_fit_time", "model", "rds"))
  edges_time <- as_tibble(arcs(bn_time), .name_repair="minimal")
  if (nrow(edges_time) > 0) {
    colnames(edges_time) <- c("from", "to")
  }
  readr::write_csv(edges_time, stamp("models/bn_edges_time", "model", "csv"))

  # Plot time-lagged DAG
  if (nrow(edges_time) > 0) {
    g_time <- graph_from_data_frame(edges_time, directed=TRUE, vertices=tibble(name=colnames(df_two_disc)))
  } else {
    g_time <- make_empty_graph(n=ncol(df_two_disc), directed=TRUE)
    V(g_time)$name <- colnames(df_two_disc)
  }
  p_time <- ggraph(g_time, layout="fr") +
    geom_edge_link(arrow = arrow(length = unit(2, "mm")), end_cap = circle(2, "mm"), alpha=.4) +
    geom_node_point(size=1.5, color="darkred") +
    geom_node_text(aes(label=name), repel=TRUE, size=2) +
    ggtitle("Bayesian Network (time-lagged, hc)") +
    theme_void()
  ggsave(stamp("plots/bn_time", "plot", "png"), p_time, width=10, height=8, dpi=150)
} else {
  cat("No 'time' column; skipping time-lagged BN.\n")
}

# ===== MEDIATION/MODERATION PROBES (Conditional MI) =====
cat("Computing conditional MI for mediation/moderation...\n")
# Sample <= 200 triplets (X, Y | Z)
set.seed(42)
vars <- colnames(df_disc)
n_vars <- length(vars)
max_triplets <- min(200, choose(n_vars, 3))

triplets <- list()
if (n_vars >= 3) {
  all_combos <- combn(vars, 3, simplify=FALSE)
  if (length(all_combos) > max_triplets) {
    sampled_combos <- sample(all_combos, max_triplets)
  } else {
    sampled_combos <- all_combos
  }

  for (combo in sampled_combos) {
    X <- combo[1]; Y <- combo[2]; Z <- combo[3]
    cmi <- ci.test(X, Y, Z, data=df_disc, test="mi")
    triplets[[length(triplets)+1]] <- list(X=X, Y=Y, Z=Z, cmi=cmi$statistic, pvalue=cmi$p.value)
  }
}

# Sort by CMI descending
triplets_df <- bind_rows(triplets) %>% arrange(desc(cmi))
write_json(triplets_df, stamp("models/bn_cmi_triplets", "model", "json"), auto_unbox=FALSE, pretty=TRUE)

cat("Bayesian Networks complete.\n")
