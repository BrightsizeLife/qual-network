# State-space (Kalman) models: Time -> Dimensions
library(tidyverse)
library(KFAS)
library(jsonlite)
source("R/00_utils.R")
ensure_dirs()

# Load latest data
csvs <- list.files("data", pattern="\\.csv$", full.names=TRUE)
stopifnot(length(csvs) > 0)
csv <- csvs[which.max(file.mtime(csvs))]
df_full <- readr::read_csv(csv, show_col_types=FALSE)

# Check for time
has_time <- "time" %in% colnames(df_full)
if (!has_time) {
  cat("WARNING: No 'time' column; synthesizing integer time 1..N\n")
  df_full$time <- 1:nrow(df_full)
}

df_full <- df_full %>% arrange(time)

# Load latest PCA to get k_selected
pca_files <- list.files("models", pattern="^pca_.*_model\\.rds$", full.names=TRUE)
if (length(pca_files) == 0) stop("No PCA model found; run PCA first.")
pca_obj <- readRDS(pca_files[which.max(file.mtime(pca_files))])
k_selected <- pca_obj$k_selected
if (is.null(k_selected)) k_selected <- 5
k_selected <- min(k_selected, 5)  # cap at 5
cat("Using k =", k_selected, "PCs for state-space\n")

# Extract dims and compute PC scores
df_dims <- df_full %>% select(starts_with("dim_"))
X_scaled <- scale(df_dims, center=TRUE, scale=TRUE)
pca_scores <- X_scaled %*% pca_obj$pca$rotation[, 1:k_selected, drop=FALSE]
colnames(pca_scores) <- paste0("PC", 1:k_selected)

# Fit local linear trend (level + slope) for each PC
pcs_state_list <- list()
for (i in 1:k_selected) {
  y <- pca_scores[, i]
  mod <- SSModel(y ~ SSMtrend(2, Q=list(matrix(NA), matrix(NA))), H=matrix(NA))

  # Fit
  fit <- tryCatch({
    fitSSM(mod, inits=c(0.1, 0.1, 0.1), method="BFGS")
  }, error = function(e) {
    list(model=mod)
  })

  # Smooth
  out <- KFS(fit$model, smoothing=c("state", "mean"))
  level <- out$alphahat[, 1]
  slope <- out$alphahat[, 2]

  pcs_state_list[[paste0("PC", i)]] <- list(
    level = level,
    slope = slope,
    time = df_full$time
  )
}
write_json(pcs_state_list, stamp("models/state_space_pcs", "model", "json"), auto_unbox=FALSE, pretty=TRUE)

# Identify top 6 dims by |loading on PC1|
loadings_pc1 <- abs(pca_obj$pca$rotation[, 1])
top6_idx <- order(loadings_pc1, decreasing=TRUE)[1:min(6, length(loadings_pc1))]
top6_dims <- rownames(pca_obj$pca$rotation)[top6_idx]

# Fit state-space for top dims
topdims_state_list <- list()
for (dim_name in top6_dims) {
  y <- X_scaled[, dim_name]
  mod <- SSModel(y ~ SSMtrend(2, Q=list(matrix(NA), matrix(NA))), H=matrix(NA))

  fit <- tryCatch({
    fitSSM(mod, inits=c(0.1, 0.1, 0.1), method="BFGS")
  }, error = function(e) {
    list(model=mod)
  })

  out <- KFS(fit$model, smoothing=c("state", "mean"))
  level <- out$alphahat[, 1]
  slope <- out$alphahat[, 2]

  topdims_state_list[[dim_name]] <- list(
    level = level,
    slope = slope,
    time = df_full$time
  )
}
write_json(topdims_state_list, stamp("models/state_space_topdims", "model", "json"), auto_unbox=FALSE, pretty=TRUE)

# Plot PC1 level vs time
pc1_df <- tibble(time=df_full$time, level=pcs_state_list$PC1$level)
g_pc1 <- ggplot(pc1_df, aes(x=time, y=level)) +
  geom_line(color="steelblue") +
  ggtitle("State-Space: PC1 Level over Time") +
  xlab("Time") + ylab("PC1 Level (smoothed)") +
  theme_minimal()
ggsave(stamp("plots/state_space_pc1_level", "plot", "png"), g_pc1, width=8, height=5, dpi=150)

cat("State-space models complete.\n")
