# Dependency check
pkgs <- c("tidyverse","readr","ggplot2","mvtnorm","bnlearn","igraph","ggraph","psych","irr","irrCAC","KFAS","jsonlite","quarto")
inst <- installed.packages()[,"Package"]
missing <- setdiff(pkgs, inst)

if (length(missing) > 0) {
  cat("MISSING DEPENDENCIES. Run:\n")
  cat("install.packages(c(", paste(sprintf('"%s"', missing), collapse=", "), "), repos='https://cloud.r-project.org')\n", sep="")
  quit(status=1)
}
cat("All dependencies OK\n")
