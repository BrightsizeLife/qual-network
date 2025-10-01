# qual-network pipeline
RSCRIPT=Rscript

.PHONY: all pipeline data irr pca bn statespace reports clean

# Full automated pipeline
pipeline: data irr pca bn statespace reports

# Legacy target (simple version)
all: data pca bn

# Data generation
data:
	$(RSCRIPT) R/01_simulate_data_full.R

# IRR analysis
irr:
	$(RSCRIPT) R/02_irr_analysis.R

# PCA with automated k selection
pca:
	$(RSCRIPT) R/04_pca_auto_k.R

# Bayesian Networks (static + time-lagged)
bn:
	$(RSCRIPT) R/05_bayesian_networks.R

# State-space models
statespace:
	$(RSCRIPT) R/06_state_space.R

# Generate HTML reports
reports:
	$(RSCRIPT) R/09_render_reports.R

# Clean outputs
clean:
	rm -f models/* plots/* reports/*.html data/tagged_long.csv data/tagging_guidelines.md
