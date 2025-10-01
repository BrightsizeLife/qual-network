# Social Pull Orchestrator
# Normalizes posts from public sources into CSV: entity | source | meta_data | text
library(yaml)
library(dplyr)
source("R/00_utils.R")
source("R/11_hn_pull.R")
source("R/12_reddit_pull.R")

ensure_dirs()

# Load config
config_path <- "config/social_sources.yml"
if (!file.exists(config_path)) {
  stop("Missing config/social_sources.yml")
}

config <- read_yaml(config_path)

cat("=== Social Pull v0 ===\n")
cat("Config loaded from:", config_path, "\n\n")

# Collect all posts
all_data <- list()
errors <- list()

# Hacker News
if (!is.null(config$hackernews)) {
  hn_result <- tryCatch({
    pull_hn(config$hackernews)
  }, error = function(e) {
    errors[[length(errors) + 1]] <- sprintf("hackernews: %s", e$message)
    cat(sprintf("hackernews: ERROR: %s\n", e$message))
    NULL
  })

  if (!is.null(hn_result) && nrow(hn_result) > 0) {
    all_data[[length(all_data) + 1]] <- hn_result
  }
}

# Reddit
if (!is.null(config$reddit)) {
  reddit_result <- tryCatch({
    pull_reddit(config$reddit)
  }, error = function(e) {
    errors[[length(errors) + 1]] <- sprintf("reddit: %s", e$message)
    cat(sprintf("reddit: ERROR: %s\n", e$message))
    NULL
  })

  if (!is.null(reddit_result) && nrow(reddit_result) > 0) {
    all_data[[length(all_data) + 1]] <- reddit_result
  }
}

# Twitter (stub)
if (!is.null(config$twitter) && config$twitter$enabled) {
  cat("twitter: disabled (not implemented; requires X_BEARER)\n")
}

# LinkedIn (stub)
if (!is.null(config$linkedin) && config$linkedin$enabled) {
  cat("linkedin: disabled (not implemented; use official API)\n")
}

# Combine and deduplicate
if (length(all_data) == 0) {
  cat("\n❌ FAILED: No data retrieved from any source\n")
  if (length(errors) > 0) {
    cat("\nErrors:\n")
    for (err in errors) cat("  -", err, "\n")
  }
  quit(status = 1)
}

combined <- bind_rows(all_data)

# Deduplicate by (source, entity)
combined <- combined %>%
  distinct(source, entity, .keep_all = TRUE)

# Validation
cat("\n=== Validation ===\n")
cat("Total rows:", nrow(combined), "\n")
cat("Rows by source:\n")
source_counts <- combined %>% group_by(source) %>% summarise(count = n())
print(as.data.frame(source_counts))

if (nrow(combined) < 20) {
  cat("\n❌ FAILED: Too few rows; check API config or rate limits.\n")
  quit(status = 1)
}

# Save with timestamped filename
outfile <- stamp("data/social_pull", "web_crawl", "csv")
write.csv(combined, outfile, row.names = FALSE)

cat("\n✅ SUCCESS\n")
cat("Output:", outfile, "\n")
cat("\n=== Preview (first 5 rows) ===\n")
preview <- combined %>%
  head(5) %>%
  mutate(
    meta_len = nchar(meta_data),
    text_preview = substr(text, 1, 80)
  ) %>%
  select(entity, source, meta_len, text_preview)

print(as.data.frame(preview))

if (length(errors) > 0) {
  cat("\n⚠️  Warnings:\n")
  for (err in errors) cat("  -", err, "\n")
}
