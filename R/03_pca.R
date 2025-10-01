# PCA with automated k selection using 3 methods: Parallel Analysis, Elbow, CV
library(tidyverse)
library(psych)
library(jsonlite)
source("R/00_utils.R")
ensure_dirs()

# Load latest data
csvs <- list.files("data", pattern="\\.csv$", full.names=TRUE)
stopifnot(length(csvs) > 0)
csv <- csvs[which.max(file.mtime(csvs))]
df <- readr::read_csv(csv, show_col_types=FALSE)
X <- df %>% select(starts_with("dim_")) %>% mutate(across(everything(), as.numeric))

# Standardize
X_scaled <- scale(X, center=TRUE, scale=TRUE)
n <- nrow(X_scaled)
p <- ncol(X_scaled)

# Run PCA
pca <- prcomp(X_scaled, center=FALSE, scale.=FALSE)
eigenvalues <- pca$sdev^2
cumvar <- cumsum(eigenvalues) / sum(eigenvalues)

# METHOD 1: Parallel Analysis (Horn)
cat("Running Parallel Analysis...\n")
pa_result <- fa.parallel(X_scaled, fa="pc", n.iter=100, plot=FALSE, sim=TRUE)
k_pa <- pa_result$ncomp

# METHOD 2: Elbow (2nd derivative)
cat("Computing Elbow...\n")
if (length(eigenvalues) >= 3) {
  d1 <- diff(eigenvalues)
  d2 <- diff(d1)
  k_elbow <- which.max(abs(d2)) + 1  # +1 because diff reduces length
  k_elbow <- min(k_elbow, p)
} else {
  k_elbow <- 1
}

# METHOD 3: 5-fold CV reconstruction RMSE
cat("Running 5-fold CV...\n")
set.seed(42)
folds <- cut(seq(1,n), breaks=5, labels=FALSE)
k_max <- min(20, p)
rmse_by_k <- numeric(k_max)

for (k in 1:k_max) {
  fold_rmse <- numeric(5)
  for (fold_i in 1:5) {
    test_idx <- which(folds == fold_i)
    train_idx <- setdiff(1:n, test_idx)

    pca_train <- prcomp(X_scaled[train_idx,], center=FALSE, scale.=FALSE)
    scores_train <- pca_train$x[,1:k, drop=FALSE]
    loadings <- pca_train$rotation[,1:k, drop=FALSE]

    # Project test onto train PCs
    scores_test <- X_scaled[test_idx,, drop=FALSE] %*% loadings
    recon_test <- scores_test %*% t(loadings)

    fold_rmse[fold_i] <- sqrt(mean((X_scaled[test_idx,] - recon_test)^2))
  }
  rmse_by_k[k] <- mean(fold_rmse)
}
k_cv <- which.min(rmse_by_k)

# MAJORITY VOTE
candidates <- c(parallel=k_pa, elbow=k_elbow, cv=k_cv)
cat("Candidates:", paste(names(candidates), candidates, sep="=", collapse=", "), "\n")

# Majority vote; if tie, pick smallest k reaching >=80% cumvar
vote_table <- table(candidates)
if (max(vote_table) >= 2) {
  k_final <- as.numeric(names(vote_table)[which.max(vote_table)])
} else {
  # Tie: pick smallest k with cumvar >= 0.80
  k80 <- which(cumvar >= 0.80)[1]
  if (is.na(k80)) k80 <- min(candidates)
  k_final <- min(k80, min(candidates))
}

cat("Selected k_final =", k_final, "\n")

# Save PCA model with k_selected stored
pca_out <- list(pca=pca, k_selected=k_final, candidates=candidates, eigenvalues=eigenvalues, cumvar=cumvar)
saveRDS(pca_out, stamp("models/pca", "model", "rds"))

# Save loadings (top k_final)
loadings_df <- as.data.frame(pca$rotation[, 1:k_final, drop=FALSE])
loadings_df$variable <- rownames(loadings_df)
readr::write_csv(loadings_df, stamp("models/pca_loadings", "model", "csv"))

# Save selection JSON
selection_json <- list(
  selected_k = k_final,
  candidates = as.list(candidates),
  eigenvalues = eigenvalues,
  cumvar = cumvar,
  rmse_curve = rmse_by_k
)
write_json(selection_json, stamp("models/pca_selection", "model", "json"), auto_unbox=TRUE, pretty=TRUE)

# PLOTS
# Scree with k_final line
df_scree <- tibble(PC=1:length(eigenvalues), Eigenvalue=eigenvalues, CumVar=cumvar)
g_scree <- ggplot(df_scree, aes(x=PC, y=Eigenvalue)) +
  geom_line() + geom_point() +
  geom_vline(xintercept=k_final, linetype="dashed", color="red") +
  annotate("text", x=k_final, y=max(eigenvalues)*0.9, label=paste0("k=",k_final), hjust=-0.2, color="red") +
  ggtitle(paste0("PCA Scree (selected k=", k_final, ")")) +
  theme_minimal()
ggsave(stamp("plots/pca_scree_auto", "plot", "png"), g_scree, width=7, height=5, dpi=150)

# Scores PC1 vs PC2 if k_final >= 2
if (k_final >= 2) {
  scores <- as_tibble(pca$x[,1:2])
  g_scores <- ggplot(scores, aes(PC1, PC2)) + geom_point(alpha=0.5) +
    ggtitle("PCA Scores (PC1 vs PC2)") + theme_minimal()
  ggsave(stamp("plots/pca_scores_pc1_pc2", "plot", "png"), g_scores, width=7, height=5, dpi=150)
}

cat("PCA auto-k complete.\n")
