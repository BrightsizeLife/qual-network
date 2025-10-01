# qual-network pipeline
RSCRIPT=Rscript

.PHONY: all pipeline data irr pca bn statespace reports clean

# Full automated pipeline
pipeline: data irr pca bn statespace reports

# Alias for pipeline
all: pipeline

# Data generation
data:
	$(RSCRIPT) R/01_generate_data.R

# IRR analysis
irr:
	$(RSCRIPT) R/02_irr.R

# PCA with automated k selection
pca:
	$(RSCRIPT) R/03_pca.R

# Bayesian Networks (static + time-lagged)
bn:
	$(RSCRIPT) R/04_bayesian_networks.R

# State-space models
statespace:
	$(RSCRIPT) R/05_state_space.R

# Generate HTML reports
reports:
	$(RSCRIPT) R/08_render_reports.R

# Clean all generated outputs
clean:
	rm -f data/*.csv data/tagged_long.csv
	rm -f models/*.rds models/*.json models/*.csv
	rm -f plots/*.png
	rm -f reports/*.html
