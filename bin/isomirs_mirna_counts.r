#!/usr/bin/env Rscript
#
# Process output from miraligner and transform it into the "regular" 
# counts table
# By default considers all isomiRs as the "mature" miRNA
# You can change this in isoCounts() section
#
# Requires: isomiRs (tested with version 1.9.1) https://github.com/lpantano/isomiRs; pheatmap (optional)

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

## Help section
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
#INPUT_DIR <- "/mnt/nfs/home/422653/000000-My_Documents/smallRNA-Seq/alca_cevy_reanalysisAllRuns2/rna_quantification/mirna_miraligner_11032023"
#OUTPUT_DIR <- INPUT_DIR

SUFFIX=".mirna$"

#dir.create(OUTPUT_DIR, recursive = T)

getwd()
# setwd(INPUT_DIR)

####################################################################################################
### Preparation
# Make list of input files
#fn_list<-list.files(path = INPUT_DIR, pattern = SUFFIX, full.names = T)
fn_list <- strsplit(INPUT_DIR, " ")[[1]]

# Make fake DE table, just to load the data easily
de <- data.frame(row.names = gsub(".mirna", "", gsub(".*/", "", fn_list), fixed = T),
                 patient = gsub(".mirna", "", gsub(".*/", "", fn_list), fixed = T),
                 condition = c(rep("dummy1", round(length(fn_list)/2)), rep("dummy2", length(fn_list)-round(length(fn_list)/2))))
de
####################################################################################################
### Load the data and make table
library("isomiRs") # >devtools::install_git("https://git@git.bioconductor.org/packages/isomiRs") or bioconductor stable >source("https://bioconductor.org/biocLite.R"); biocLite("isomiRs")
library("dplyr")

# Load the files - take some time
ids <- IsomirDataSeqFromFiles(fn_list, coldata=de, canonicalAdd = TRUE, uniqueMism = TRUE, rate = 0)

#ids <- IsomirDataSeqFromFiles(fn_list, coldata=de, rate = 0, canonicalAdd = TRUE, uniqueMism = TRUE)# Require only cannonical add (AT) and remove (GC); require unique mirna match after mismatch   
#                              minHits=0 # From version 1.9.1
# This works in a suspicious way - probably not at all!
# mircounts <- isoCounts(ids, ref = FALSE, iso5 = FALSE, iso3 = FALSE, add = FALSE, subs = FALSE, 
#                        seed = FALSE, minc = 1, mins = 1) # Get the counts, separate 5' isoforms and substitutions (~SNPs)

head(assay(ids)) # See the counts

rio::export(assay(ids), paste(OUTPUT_DIR, "canonical_mirna_counts.tsv", sep="/"), format = "tsv", row.names = T)

isoAll <- isoCounts(ids, ref=T, iso5=T, iso3=T, add=T, snv=T, seed=T, minc=0, mins=0)

rio::export(assay(isoAll), paste(OUTPUT_DIR, "isomirs_counts.tsv", sep="/"), format = "tsv", row.names = T)