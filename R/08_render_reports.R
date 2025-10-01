# Render reports using knitr
library(knitr)

cat("Rendering quality report...\n")
tryCatch({
  knitr::knit2html("R/06_report_quality.Rmd", output="reports/01_dimensions_quality.html", quiet=TRUE)
  cat("Quality report rendered.\n")
}, error = function(e) {
  cat("ERROR rendering quality report:", e$message, "\n")
})

cat("Rendering models report...\n")
tryCatch({
  knitr::knit2html("R/07_report_models.Rmd", output="reports/02_structure_models.html", quiet=TRUE)
  cat("Models report rendered.\n")
}, error = function(e) {
  cat("ERROR rendering models report:", e$message, "\n")
})
