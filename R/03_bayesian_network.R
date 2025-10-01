# Learns a BN using bnlearn::hc, plots with igraph/ggraph, saves bn fit + edge list.
library(tidyverse)
library(bnlearn)
library(igraph)
library(ggraph)
source("R/00_utils.R")
ensure_dirs()

csvs <- list.files("data", pattern="\\.csv$", full.names=TRUE)
stopifnot(length(csvs) > 0)
csv <- csvs[which.max(file.mtime(csvs))]
df <- readr::read_csv(csv, show_col_types=FALSE) %>% select(starts_with("dim_"))

# Discretize for structure learning robustness (equal width bins)
df_disc <- discretize(df, method="interval", breaks=3)

bn <- hc(df_disc)          # hill-climbing
fit <- bn.fit(bn, df_disc)

# Save model + edges
saveRDS(fit, stamp("models/bn_fit", "model", "rds"))
edges <- as_tibble(arcs(bn), .name_repair="minimal") %>% rename(from=from, to=to)
readr::write_csv(edges, stamp("models/bn_edges", "model", "csv"))

# Plot DAG with igraph/ggraph
g <- graph_from_data_frame(edges, directed=TRUE, vertices=tibble(name=colnames(df_disc)))
p <- ggraph(g, layout="fr") +
  geom_edge_link(arrow = arrow(length = unit(3, "mm")), end_cap = circle(2, "mm"), alpha=.5) +
  geom_node_point(size=2) +
  geom_node_text(aes(label=name), repel=TRUE, size=3) +
  ggtitle("Bayesian Network (hc) — discretized dims")
ggsave(stamp("plots/bn_graph", "plot", "png"), p, width=8, height=6, dpi=150)
