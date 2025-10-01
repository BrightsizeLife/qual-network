# Runs PCA (prcomp), saves model object (RDS), variance plot and biplot as PNG.
library(tidyverse)
library(ggplot2)
source("R/00_utils.R")
ensure_dirs()

# Find newest data CSV
csvs <- list.files("data", pattern="\\.csv$", full.names=TRUE)
stopifnot(length(csvs) > 0)
csv <- csvs[which.max(file.mtime(csvs))]
df <- readr::read_csv(csv, show_col_types=FALSE)
X <- df %>% select(starts_with("dim_")) %>% mutate(across(everything(), as.numeric))

pca <- prcomp(X, center=TRUE, scale.=TRUE)
saveRDS(pca, stamp("models/pca", "model", "rds"))

# Scree plot
var_expl <- pca$sdev^2 / sum(pca$sdev^2)
df_scree <- tibble(PC = paste0("PC", seq_along(var_expl)), Variance = var_expl, Ord = seq_along(var_expl))
g1 <- ggplot(df_scree, aes(x=Ord, y=Variance)) +
  geom_line() + geom_point() +
  xlab("Principal Component") + ylab("Variance Explained") +
  ggtitle("PCA Scree Plot")
ggsave(stamp("plots/pca_scree", "plot", "png"), g1, width=7, height=5, dpi=150)

# First two PCs biplot (scores)
scores <- as_tibble(pca$x[,1:2])
g2 <- ggplot(scores, aes(PC1, PC2)) + geom_point(alpha=.5) +
  ggtitle("PCA Scores (PC1 vs PC2)")
ggsave(stamp("plots/pca_scores_pc1_pc2", "plot", "png"), g2, width=7, height=5, dpi=150)
