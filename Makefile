# Simple pipeline
RSCRIPT=Rscript

.PHONY: all data pca bn clean

all: data pca bn

data:
	$(RSCRIPT) R/01_simulate_data.R

pca:
	$(RSCRIPT) R/02_pca.R

bn:
	$(RSCRIPT) R/03_bayesian_network.R

clean:
	rm -f models/* plots/*
