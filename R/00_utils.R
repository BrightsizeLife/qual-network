# Utilities: timestamp + dir helpers
ts <- function() format(Sys.time(), "%Y%m%d_%H%M%S")
ensure_dirs <- function() {
  for (d in c("data","models","plots")) if (!dir.exists(d)) dir.create(d, recursive=TRUE)
}
stamp <- function(base, kind=c("model","plot","web_crawl"), ext="rds") {
  kind <- match.arg(kind)
  suffix <- if (kind == "model") {
    "_model"
  } else if (kind == "plot") {
    "_plot"
  } else if (kind == "web_crawl") {
    "_web_crawl"
  } else {
    ""
  }
  paste0(base, "_", ts(), suffix, ".", ext)
}
