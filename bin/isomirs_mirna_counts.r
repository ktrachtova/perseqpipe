#!/usr/bin/env Rscript
#'
#' Process output from miraligner and transform it into the "regular" counts table.
#' By default considers all isomiRs as the "mature" miRNA.
#' @author: Karolina Trachtova
#' 
rm(list=ls(all=TRUE))

# Test if there is at least one argument: if not, return an error
args <- commandArgs(TRUE)

# Default if no arguments are given
if (length(args)< 1 ) {
  #  stop("At least one argument must be supplied (input directory).n", call.=FALSE)
  args <- c("--help")
} else if (length(args)==1) {
  # Default output directory is the same as the input directory
  args[2] <- args[1]
}

# Help section
if("--help" %in% args) {
  cat("
      Usage:
      ./isomirs_mirna_counts.R input_dir [output_dir]
      
      Example:
      ./isomirs_mirna_counts.R ~/results/miraligner ~/results/miraligner/counts")
  
  q(save="no")
}

INPUT_DIR <- args[1]
OUTPUT_DIR <- args[2]

SUFFIX=".mirna$"

####################################################################################################
# Preparation
# Make list of input files
fn_list <- strsplit(INPUT_DIR, " ")[[1]]

# Make fake DE table, just to load the data easily
sample_names <- gsub(".mirna", "", gsub(".*/", "", fn_list), fixed = T)
if (length(fn_list) == 1) {
  # A one-level condition is rejected by the DESeq-compatible constructor.
  de <- data.frame(row.names = sample_names)
} else {
  de <- data.frame(row.names = sample_names,
                   patient = sample_names,
                   condition = c(rep("dummy1", round(length(fn_list)/2)), rep("dummy2", length(fn_list)-round(length(fn_list)/2))))
}

####################################################################################################
# Load the data and make table
library("isomiRs")
library("dplyr")

# Load the files
ids <- IsomirDataSeqFromFiles(fn_list, coldata=de, canonicalAdd = TRUE, uniqueMism = TRUE, rate = 0)

# Export canonical mirna counts
rio::export(assay(ids), paste(OUTPUT_DIR, "canonical_mirna_counts.tsv", sep="/"), format = "tsv", row.names = T)

# Get isomir counts. Some isomiRs versions cannot construct a one-column
# SummarizedExperiment. For one sample, process a temporary duplicate with a
# unique filename and retain only the first result column.
if (length(fn_list) == 1) {
  duplicate_file <- file.path(tempdir(), paste0(sample_names, "_duplicate.mirna"))
  file.copy(fn_list, duplicate_file, overwrite = TRUE)
  duplicate_names <- c(sample_names, paste0(sample_names, "_duplicate"))
  duplicate_de <- data.frame(row.names = duplicate_names,
                             patient = duplicate_names,
                             condition = c("dummy1", "dummy2"))
  duplicate_ids <- IsomirDataSeqFromFiles(c(fn_list, duplicate_file),
                                          coldata = duplicate_de,
                                          canonicalAdd = TRUE,
                                          uniqueMism = TRUE,
                                          rate = 0)
  isoAll <- isoCounts(duplicate_ids, ref = TRUE, iso5 = TRUE, iso3 = TRUE,
                      add = TRUE, snv = TRUE, seed = TRUE, minc = 0, mins = 0)
  isoAll <- isoAll[, 1, drop = FALSE]
} else {
  isoAll <- isoCounts(ids, ref=T, iso5=T, iso3=T, add=T, snv=T, seed=T, minc=0, mins=0)
}

# Export isomirs counts
rio::export(assay(isoAll), paste(OUTPUT_DIR, "isomirs_counts.tsv", sep="/"), format = "tsv", row.names = T)