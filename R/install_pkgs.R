pkgs <- c("tidyverse","mvtnorm","bnlearn","igraph","ggraph","ggplot2","readr")
inst <- installed.packages()[,"Package"]
for (p in pkgs) if (!p %in% inst) install.packages(p, repos="https://cloud.r-project.org")
cat("OK\n")
