# Render reports using quarto or knitr if pandoc not available
library(knitr)

# Try knitr::knit2html as fallback
cat("Rendering quality report...\n")
tryCatch({
  knitr::knit2html("R/07_report_quality.Rmd", output="reports/01_dimensions_quality.html", quiet=TRUE)
  cat("Quality report rendered.\n")
}, error = function(e) {
  cat("ERROR rendering quality report:", e$message, "\n")
})

cat("Rendering models report...\n")
tryCatch({
  knitr::knit2html("R/08_report_models.Rmd", output="reports/02_structure_models.html", quiet=TRUE)
  cat("Models report rendered.\n")
}, error = function(e) {
  cat("ERROR rendering models report:", e$message, "\n")
})
