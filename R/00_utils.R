# Utilities: timestamp + dir helpers
ts <- function() format(Sys.time(), "%Y%m%d_%H%M%S")
ensure_dirs <- function() {
  for (d in c("data","models","plots")) if (!dir.exists(d)) dir.create(d, recursive=TRUE)
}
stamp <- function(base, kind=c("model","plot"), ext="rds") {
  kind <- match.arg(kind)
  suffix <- if (kind == "model") "_model" else "_plot"
  paste0(base, "_", ts(), suffix, ".", ext)
}
