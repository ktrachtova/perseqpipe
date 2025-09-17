#!/usr/bin/env Rscript

#' R script for DE analysis - part of PerSeqPIPE Nextflow workflow 
#' @author Karolina Trachtova
#' @description R script that generates various matrices of counts (raw,
#' edgeR TNM, deseq2 count, VST counts) as well as performs DE analysis
#' using provided design file
#' INPUTS:
#'   - counts_mirna:         [file]    matrix of canonical mirna counts
#'   - counts_isomirs:       [file]    matrix of isomirs counts
#'   - design_file:          [file]    TXT tab- or comma-separated file with min 2 or max 3 columns (sample, condition, ?batch?)
#'   - generate_counts_only: [boolean] Should only normalized counts be generated (no DE analysis)? 


# Load required libraries
library(edgeR)
library(DESeq2)
library(dplyr)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

##### Functions ###############################################################
rownames_to_column <- function(res) {
  # Convert to data frame
  res_df <- as.data.frame(res)
  
  # Add gene names as a proper column
  res_df$gene <- rownames(res_df)
  
  # Reorder columns to have gene first
  res_df <- res_df[, c("gene", setdiff(names(res_df), "gene"))]
  
  return(res_df)
}

# Function to create matrix of raw counts and matrix of normalized counts
# that will be added to the final DE table; samples will be renamed
# to contain in its name both condition and whether it is raw/norm count column
create_raw_norm_counts <- function(dds) {
  
  # Extract raw and normalized counts
  raw_counts <- counts(dds, normalized = FALSE) %>%
    as.data.frame() %>%
    tibble::rownames_to_column("gene")
  
  norm_counts <- counts(dds, normalized = TRUE)
  
  vst_counts <- assay(DESeq2::varianceStabilizingTransformation(dds))
  
  # Check if batch column is in colData and remove batch effect
  if ("batch" %in% colnames(colData(dds))) {
    batch <- colData(dds)$batch
    condition <- colData(dds)$condition
    
    norm_counts <- limma::removeBatchEffect(norm_counts, batch = batch, design = model.matrix(~ condition))
    
    vst_counts <- limma:removeBatchEffect(vst_counts, batch = batch, design = model.matrix(~ condition))
  }
  
  norm_counts <- as.data.frame(norm_counts) %>%
    tibble::rownames_to_column("gene")
  
  vst_counts <- as.data.frame(vst_counts) %>%
    tibble::rownames_to_column("gene")
  
  # Add condition info to sample names
  sample_conditions <- colData(dds)$condition
  names(sample_conditions) <- colnames(dds)
  
  rename_with_condition <- function(count_df, count_type) {
    old_names <- colnames(count_df)[-1]
    new_names <- paste0(old_names, "_", count_type, "_", sample_conditions[old_names])
    colnames(count_df)[-1] <- new_names
    return(count_df)
  }
  
  raw_counts <- rename_with_condition(raw_counts, "raw")
  norm_counts <- rename_with_condition(norm_counts, "norm")
  vst_counts <- rename_with_condition(vst_counts, "vst")
  
  merged_counts <- raw_counts %>%
    dplyr::left_join(norm_counts, by = "gene") %>%
    dplyr::left_join(vst_counts, by = "gene")
  
  return(merged_counts)
}


##### Parse input parameters ##################################################

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Initialize variables
# mirna_exp <- 20
# mirna_sample <- 6
# isomirs_exp <- 20
# isomirs_sample <- 6

# Testing 1
#counts_mirna <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/rna_quantification/mirna/canonical_mirna_counts.tsv"
#counts_isomirs <- NULL
#design_file <- NULL
#generate_counts_only <- TRUE
#setwd("/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/de1")

# Testing 2
#counts_mirna <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_test/rna_quantification/mirna/canonical_mirna_counts.tsv"
#counts_mirna <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_test/GSE262424_read_counts.tsv" -> original counts from Sabine
#counts_isomirs <-  "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_test/rna_quantification/mirna/isomirs_counts.tsv"
#design_file <- "/Users/kaja/Public/nextflow/test_data/trilink_GSE262424/design_MM_PCL_EMD.txt"
#generate_counts_only <- FALSE
#setwd("/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_test/de_analysis_manual")

# Testing 3 - DEORECATED, full design file should be always supplied?
#counts_mirna <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/rna_quantification/mirna/canonical_mirna_counts.tsv"
#counts_isomirs <-  "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/rna_quantification/mirna/isomirs_counts.tsv"
#design_file <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/design_EMDvsPCL.txt"
#generate_counts_only <- FALSE
#setwd("/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/de3")

# Testing 4
#counts_mirna <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/rna_quantification/mirna/canonical_mirna_counts.tsv"
#counts_isomirs <-  "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/rna_quantification/mirna/isomirs_counts.tsv"
#design_file <- "/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/design_EMDvsPCLvsMM.txt"
#generate_counts_only <- FALSE
#setwd("/Users/kaja/Public/nextflow_results/docker_trilink_GSE262424_DE/de4")

# Parse arguments
i <- 1
while (i <= length(args)) {
  if (args[i] == "--counts_mirna") {
    counts_mirna <- args[i + 1]
    i <- i + 1
  } else if (args[i] == "--counts_isomirs") {
    counts_isomirs <- args[i + 1]
    i <- i + 1
  } else if (args[i] == "--design_file") {
    design_file <- args[i + 1]
    i <- i + 1
  } else if (args[i] == "--mirna_expression_threshold") {
    thresh_parts <- strsplit(args[i + 1], ",")[[1]]
    if (length(thresh_parts) != 2) {
      stop("Error: --mirna_expression_threshold requires two comma-separated integers, e.g., 10,3 (expression threshold, number of samples")
    }
    mirna_exp <- as.numeric(thresh_parts[1])
    mirna_sample <- as.numeric(thresh_parts[2])
    i <- i + 1
  } else if (args[i] == "--isomirs_expression_threshold") {
    thresh_parts <- strsplit(args[i + 1], ",")[[1]]
    if (length(thresh_parts) != 2) {
      stop("Error: --isomirs_expression_threshold requires two comma-separated integers, e.g., 10,3 (expression threshold, number of samples")
    }
    isomirs_exp <- as.numeric(thresh_parts[1])
    isomirs_sample <- as.numeric(thresh_parts[2])
    i <- i + 1
  }
  i <- i + 1
}

# ======= Argument Checks =======

# 1. Check that at least one of miRNA or isomiRs counts is specified
if (is.null(counts_mirna) && is.null(counts_isomirs)) {
  stop("Error: You must specify at least one of --counts_mirna or --counts_isomirs.")
}

# 2. Check if design file is specified
if (is.null(design_file)) {
  message("No design file provided. Only normalized counts will be output.")
} else {
  # 3. Check that design file exists
  if (!file.exists(design_file)) {
    stop(paste("Error: Design file does not exist:", design_file))
  }
  
  # Try to guess separator by inspecting the file
  first_line <- readLines(design_file, n = 1)
  
  if (grepl(",", first_line)) {
    sep_used <- ","
  } else if (grepl("\t", first_line)) {
    sep_used <- "\t"
  } else {
    stop("Error: Could not detect separator: neither comma nor tab found.")
  }
  
  design <- read.table(design_file, sep = sep_used, header = T)
  
  # Check column names
  valid_cols <- c("sample", "condition", "batch")
  actual_cols <- colnames(design)
  
  if (length(actual_cols) < 2 || length(actual_cols) > 3) {
    stop("Error: Design file must have min 2 and max 3 columns.")
  }
  
  if (!all(c("sample", "condition") %in% actual_cols)) {
    stop("Error: Design file must contain 'sample' and 'condition' columns.")
  }
  
  if (!all(actual_cols %in% valid_cols)) {
    stop("Error: Design file contains invalid columns. Allowed: sample, condition, batch.")
  }
  
  # Clean design matrix -> samples must be rownames, columns must be factors
  rownames(design) <- design$sample
  design$sample <- NULL
  design$condition <- factor(design$condition)
  
  # Check if the design file has a third column named 'batch'
  if ("batch" %in% colnames(design)) {
    design$batch <- factor(design$batch)
  }
  
  cat("Design File:", design_file, "\n")
  cat("Design file loaded successfully.\n")
  
}

# 3. Check that provided counts files exist
if (!is.null(counts_mirna) && !file.exists(counts_mirna)) {
  stop(paste("Error: miRNA counts file does not exist:", counts_mirna))
}
if (!is.null(counts_isomirs) && !file.exists(counts_isomirs)) {
  stop(paste("Error: isomiRs counts file does not exist:", counts_isomirs))
}

##### Read input counts ########################################################

# Read in counts data
counts_list <- list()

# Read in canonical minra counts
if (!is.null(counts_mirna)) {
  message("Reading miRNA counts from: ", counts_mirna)
  counts_mirna_data <- read.table(counts_mirna, header = TRUE, row.names = 1, sep = "\t", check.names = FALSE)
  counts_list$mirna <- counts_mirna_data # save counts into list
}

# Read in isomiRs counts
if (!is.null(counts_isomirs)) {
  message("Reading isomiRs counts from: ", counts_isomirs)
  counts_isomirs_data <- read.table(counts_isomirs, header = TRUE, row.names = 1, sep = "\t", check.names = FALSE)
  counts_list$isomirs <- counts_isomirs_data # save counts into list
}

# If design file provided, filter input counts tables to contain only columns in design
if (!is.null(design_file)) {
  if (!is.null(counts_mirna)) {
    counts_mirna_data <- counts_mirna_data[,colnames(counts_mirna_data) %in% rownames(design)]
    # sort
    counts_mirna_data <- counts_mirna_data[,match(rownames(design), colnames(counts_mirna_data))]
    counts_list$mirna <- counts_mirna_data # if design specified and counts modified, overwrite initil table
    
  }
  if (!is.null(counts_isomirs)) {
    counts_isomirs_data <- counts_isomirs_data[,colnames(counts_isomirs_data) %in% rownames(design)]
    # sort
    counts_isomirs_data <- counts_isomirs_data[,match(rownames(design), colnames(counts_isomirs_data))]
    counts_list$isomirs <- counts_isomirs_data # if design specified and counts modified, overwrite initil table
  }
}

# Save cleaned counts and design into R data object
analysis_data_cleaned <- list(
  mirna_counts = if (exists("counts_mirna_data")) counts_mirna_data else NULL,
  isomirs_counts = if (exists("counts_isomirs_data")) counts_isomirs_data else NULL,
  design_df = if (exists("design")) design else NULL
)

# Save the list to a file
saveRDS(analysis_data_cleaned, file = "analysis_data_cleaned.rds")

##### Counts normalization #####################################################

# If user does not provide design file, do dummy normalization and at least
# provide this type of counts
if (is.null(design_file)) {
  
  # Runs normalization for mirna and/or isomirs
  for (name in names(counts_list)) {
    message("Normalizing ", name, " counts...")
    
    count_data <- counts_list[[name]]
    
    # -------------------------------
    # 1. EdgeR TMM Normalization
    # -------------------------------
    
    # Create a DGEList object for edgeR normalization
    dge <- DGEList(counts = count_data)
    dge <- calcNormFactors(dge, method = "TMM")  # TMM normalization
    tmm_counts <- cpm(dge, normalized.lib.sizes = TRUE)
    tmm_counts_df <- rownames_to_column(tmm_counts)
    write.table(
      tmm_counts_df,
      file = paste0("normalized_tmm_counts_", name, ".tsv"),
      sep = "\t", quote = FALSE, row.names = FALSE
    )
    
    # -------------------------------
    # 2. DESeq2 Normalization (Size Factors)
    # -------------------------------
    
    # Create a DESeqDataSet for DESeq2
    dds <- DESeqDataSetFromMatrix(countData = count_data, colData = DataFrame(condition = rep("Condition", ncol(count_data))), design = ~1)
    dds <- DESeq(dds)
    deseq2_counts <- counts(dds, normalized = TRUE)
    deseq2_counts_df <- rownames_to_column(deseq2_counts)
    write.table(
      deseq2_counts_df,
      file = paste0("normalized_deseq2_counts_", name, ".tsv"),
      sep = "\t", quote = FALSE, row.names = FALSE
    )
    
    # -------------------------------
    # 3. DESeq2 VST (Variance-Stabilizing Transformation)
    # -------------------------------
    
    # Perform VST normalization
    vst_matrix <- assay(DESeq2::varianceStabilizingTransformation(dds))
    vst_matrix_df <- rownames_to_column(vst_matrix)
    write.table(
      vst_matrix_df,
      file = paste0("normalized_vst_counts_", name, ".tsv"),
      sep = "\t", quote = FALSE, row.names = FALSE
    )
  }
  
  cat("Normalization completed.")

} else {
  
  print("Design file provided, running DE analysis with DESeq2.")
}

##### Run DE analysis ##########################################################

# Check design file is specified and --generate-counts-only is FALSE
if (!is.null(design_file)) {
  
  # Run DE analysis for mirna and/or isomirs
  for (name in names(counts_list)) {
    
    message("#####################################")
    message("DE analysis for ", name, " counts...")
    
    count_data <- counts_list[[name]]
    
    # Check if the design file has a third column named 'batch'
    use_batch <- "batch" %in% colnames(design)
    if (use_batch) {
      print("Batch effect specified in design file.")
    }
  
    # Create a DESeqDataSet object from the count matrix and design file
    counts_matrix <- count_data
    
    # Ensure the sample names in the design file match the column names of the counts matrix
    if (!all(design$sample %in% colnames(counts_matrix))) {
      stop("Error: The sample names in the design file do not match the columns in the counts matrix!")
    }
  
    # Create DESeq2 object
    # If batch column exists, include it in the design formula
    if (use_batch) {
      message("Including batch effect in the model\n")
      dds <- DESeqDataSetFromMatrix(countData = counts_matrix, colData = design, design = ~ batch + condition)
    } else {
      message("No batch effect supplied, proceeding without batch correction.\n")
      dds <- DESeqDataSetFromMatrix(countData = counts_matrix, colData = design, design = ~ condition)
    }
    
    # Filter out sequences not achieving expression threshold in given number of samples
    # mirna/isomirs can have different thresholds hence two different chunks of code
    if (name == "mirna") {
      if (!is.null(mirna_exp) && !is.null(mirna_sample)) {
        message(sprintf("Filtering miRNA counts based on expression ≥ %d in at least %d samples",
                        mirna_exp, mirna_sample))
        dds <- dds[rowSums(counts(dds) >= mirna_exp) >= mirna_sample, ]
      }
    }
    
    if (name == "isomirs") {
      if (!is.null(mirna_exp) && !is.null(mirna_sample)) {
        message(sprintf("Filtering isomiRs counts based on expression ≥ %d in at least %d samples",
                        isomirs_exp, isomirs_sample))
        dds <- dds[rowSums(counts(dds) >= isomirs_exp) >= isomirs_sample, ]
      }
    }
  
    # Perform DE analysis
    dds <- DESeq(dds)
  
    # Create the file name using the timestamp
    dds_filename <- paste0("dds_", name, ".rds")
    # Save the dds object as an RDS file
    saveRDS(dds, file = dds_filename)
    
    # Check how many conditions supplied, if more than 2 do LRT and save results
    if (length(levels(dds$condition)) >= 3){
      if (use_batch) {
        dds_lrt <- DESeq(dds, test = "LRT", reduced = ~ batch)
      } else {
        dds_lrt <- DESeq(dds, test = "LRT", reduced = ~ 1)
      }
      res_lrt <- results(dds_lrt) %>%
        as.data.frame() %>%
        tibble::rownames_to_column("gene") %>%
        dplyr::select(gene,
                      baseMean = baseMean,
                      stat_lrt = stat,
                      pvalue_lrt = pvalue,
                      padj_lrt = padj)
      res_lrt <- res_lrt %>%
        arrange(padj_lrt)
      # Save the dds object
      dds_lrt_filename <- paste0("dds_lrt_", name, ".rds")
      saveRDS(dds_lrt, file = dds_lrt_filename)
      # Save the table
      # output_file <- paste0("DE_analysis_", name, "_LRT_results.tsv")
      # write.table(res_lrt, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)
    }
    
    # Get all levels of condition
    cond_levels <- levels(dds$condition)
    comparisons <- combn(cond_levels, 2, simplify = FALSE)  # Generate pairwise comparisons

    # Initialize list to store each comparison
    pairwise_results <- list()
    
    for (comp in comparisons) {
      cond_a <- comp[1]
      cond_b <- comp[2]
      comp_name <- paste0(cond_a, "_vs_", cond_b)
      message("Performing comparison: ", cond_a, " vs ", cond_b)
      
      # Get DE results
      res <- results(dds, contrast = c("condition", cond_a, cond_b))
      
      # Convert to clean data frame
      res_df <- as.data.frame(res) %>%
        tibble::rownames_to_column("gene") %>%
        dplyr::select(gene,
                      !!paste0("logFC_", comp_name) := log2FoldChange,
                      !!paste0("stat_", comp_name) := stat,
                      !!paste0("pval_", comp_name) := pvalue,
                      !!paste0("padj_", comp_name) := padj)
      
      pairwise_results[[comp_name]] <- res_df
      
    }
    
    # In case we have >= 3 conditions, we need to merge all comparisons
    if (length(levels(dds$condition)) >= 3) {
      # do LRT and get res_lrt
      # merge with pairwise_results as you have now
      final_results <- res_lrt
      for (comp_name in names(pairwise_results)) {
        final_results <- left_join(final_results, pairwise_results[[comp_name]], by = "gene")
      }
    } else {
      # only 2 conditions: final_results is just that single pairwise result
      final_results <- pairwise_results[[1]]
    }
    
    final_results <- final_results %>%
      arrange(padj_lrt)
    
    # Save result
    output_file <- paste0("DE_analysis_", name, "_", paste(levels(dds$condition), collapse = "_"), "_results.tsv")
    write.table(final_results, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)

    # Obtain raw and normalized counts - order of rows==sequences('gene' column)
    # will be identical to the DE table so its easy to merge
    counts_table <- create_raw_norm_counts(dds)
    output_file <- paste0("DE_analysis_", name, "_", paste(levels(dds$condition), collapse = "_"), "_counts.tsv")
    write.table(counts_table, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)
    
    message("All pairwise DE comparisons for ", name, " completed.\n")

  }
} else {
  cat("Skipping differential expression analysis. Either no design file or --generate-counts-only flag is set.\n")
}

# Save full environment and history
save.image(paste0("de_analysis_mirna_isomirs.rds"))

