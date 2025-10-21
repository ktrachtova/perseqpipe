# PerSeqPIPE: Differential Expression Analysis

The Differential Expression Analysis module (**DE_ANALYSIS**) can be executed in two modes. If no design file is provided (using the `--design` option), the module generates only raw and normalized counts (including edgeR TMM, VST, and DESeq2-normalized values). If a design file is supplied, a full differential expression analysis is performed using DESeq2.

The **DE_ANALYSIS** module is executed separately for miRNAs/isomiRs (using counts obtained from the **MIRNA_QUANTIFICATION** module) and for all other RNA classes (using counts obtained from the **SNCRNA_QUANTIFICATION** module).

## Design file specification

The design file must contain at least two columns (`sample` and `condition`) and may include an optional third column (`batch`). The sample names specified in the **sample column must exactly match the sample names listed in the input samplesheet file**; otherwise, the pipeline will fail.

The file can be comma- or tab-delimited. Please note that using special characters (such as spaces, hashes, slashes, etc.) in sample names, conditions, or batch values may cause the analysis to fail. It is strongly recommended that the design file only contain alphanumeric characters, hyphens, and underscores.

Example design file with only sample and condition columns:
```
sample,condition
sample1,cond1
sample2,cond2
```

Example design file with sample , condition and batch columns (batch effect here is a sequencing run):

```
sample,condition,batch
sample1,cond1,run1
sample2,cond1,run2
sample3,cond2,run1
sample4,cond2,run2
```

### Providing partial design file

User can provide a partial design file as an input (for example, only condition A and B and omitting condition C). In that case only conditions in the design file will be compared and samples belonging to conditions not stated in the design file will be filtered out prior to generating normalized counts and running DESeq2 analysis.

## Generating normalized counts

### Without design file

Several types of normalized counts are calculated if no design file is provided, separately for miRNA, isomiRs and all other RNA classes.

* DESeq2 normalized counts obtained through command `counts(dds, normalized = TRUE)`
* VST normalized counts
* edgeR TMM counts

Each type of normalized counts has its own, tab-separated, output text file. Since no design file was provided, all normalized counts were generated using dummy design formula, treating all samples as a single group. As a result, the normalized counts reflect only library size and distributional adjustments, without accounting for any experimental variables.

### With design file

If a design file is provided, tables with normalized counts (DESeq2 and VST) are extracted after the DE analysis. This means that in contrast to counts created without design file, DESeq2 and VST normalization are applied within the context of the specified model (e.g., including condition or batch effects). Hence, the resulting normalized counts incorporate the structure of the experimental design, ensuring that unwanted sources of variation (e.g., batch effects) are appropriately modeled or removed, leading to more biologically meaningful expression estimates.

If batch effect is given within the design file, normalized counts are extracted after removing the batch effect from the counts using limma function `RemoveBatchEffect()`. 

## Differential expression analysis

If both matrix of counts and design is specified, DE analysis using DESeq2 R package will be performed. Currently, following tests will be always performed:

* pairwise comparison of all conditions
* likelihood ratio test (LRT) of all conditions 

### Pairwise testing

If design file looks like following:
```
sample,condition
sample1,AA
sample2,AA
sample3,AA
sample4,BB
sample5,BB
sample6,BB
sample7,CC
sample8,CC
sample9,CC
```

Following pair-wise comparisons will be done:
* AA vs BB
* AA vs CC
* BB vs CC

If more than 3 distinct conditions are provided in the design file, all pair-wise comparisons will be evaluated through Wald-test.

### Likelihood ratio test (LRT)

Additionally, likelihood ratio test (LRT) will also be performed. The likelihood ratio test (LRT) for count data, as implemented in DESeq2, is conceptually similar to an analysis of variance (ANOVA) in linear models. In simple terms, it tests whether a given gene or feature shows statistically significant differences in expression across all tested conditions by comparing a full model (with condition effects) to a reduced model (without them). This test is particularly useful when comparing more than two conditions, as it provides a global test for any differences in expression across groups. For more information, see DESeq2 documentation on [LRT](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html#likelihood-ratio-test).

## Filtering low-expressed sequences

It is highly recommended to filter out low-expressed sequences (for both miRNA/isomiRs and sncRNA) prior to evaluating differentially expressed genes. This improves dispersion estimation and hence avoid unreliable fold changes and p-values. Unless specified otherwise, all sequences (for both miRNA/isomiRs and sncRNA DE analysis) are used. However, user can specify parameter `--sncrna_expression_thresholds X,Y` for sncRNA (or alternatively `—-mirna_expression_thresholds` for miRNA and `--isomirs_expression_thresholds` for isomiRs) to set expression threshold for specific number of samples. For example, `--sncrna_expression_thresholds 20,3` will filter out any sncRNA sequences that do not have expression of at least 20 in at least 3 samples. This filtering happens on raw matrix of counts before calculating DE genes. See section [Pre-filtering](https://bioconductor.org/packages/release/bioc/vignettes/DESeq2/inst/doc/DESeq2.html#pre-filtering) of DESeq2 documentation for more information.

It is highly recommended to use this filtering when running sncRNA DE analysis as there are usually several thousands of distinct sequences which are often present in only one or two samples which introduces strong bias into the DE analysis!

## Output files

### miRNA / isomiRs

Main outputs from miRNA/isomiRs DE analysis if design file provided by user:

* **DE_analsis_{mirna|isomirs}\_results.tsv** is a main file with DE results for miRNA and isomiRs (separately). This file contains following columns:

    * `gene` column with miRNA/isomiR name
    * `baseMean` is the average of the normalized count values, dividing by size factors, taken over all samples
    * `stat_lrt` (optional) is the value of the test statistic from LRT; present only if more there are more than 2 conditions in the design file
    * `pvalue_lrt` (optional) is the p-value of from LRT; present only if more there are more than 2 conditions in the design file
    * `padj_lrt` (optional) is the adjusted p-value from LRT; present only if more there are more than 2 conditions in the design file
    * `logFC_cond{X}_vs_cond{Y}` is log2 fold change from comparing condX vs condY
    * `stat_cond{X}_vs_cond{Y}` is the value of the test statistics from comparing condX vs condY
    * `pval_cond{X}_vs_cond{Y}` is the p-value of comparing condX vs condY
    * `padj_cond{X}_vs_cond{Y}` is the adjusted p-value of comparing condX vs condY

* **DE_analysis_{mirna|isomirs}\_counts.tsv** contains raw and normalized counts for all samples. Each column in the file is a sample. Column header format is following:

    * `{sample_id}\_{raw|norm|vst}_{condX|condY}` where raw=raw counts, norm=DESeq2 normalized counts and vst=VST counts, first column is **gene** and corresponds to the first column of the table with DE analysis results, hence both tables can be easily merged
 
    If design file contains column `batch`, function `removeBatchEffect()` from limma package will be used to remove that batch effect from counts, hence the columns **norm** and **vst** will contain counts suitable for creating plots such as heatmaps

Main outputs from miRNA/isomiRs DE analysis if design file NOT provided by user and only normalization was performed; these files are not generated if design file is provided:

* **normalized_tmm_counts_{mirna|isomirs}.tsv** contains edgeR TMM normalized counts
* **normalized_deseq2_counts_{mirna|isomirs}.tsv** contains DESeq2 normalized counts
* **normalized_vst_counts_{mirna|isomirs}.tsv** contains VST counts

Additional outputs from miRNA/isomiRs DE analysis:

* **analysis_data_cleaned.rds** is and R data object that contains counts tables for miRNA and isomiRs used for DE analysis as well as design file, saved for reproducibility purposes

### Other sncRNA

Main outputs from sncRNA DE analysis if design file provided by user:

* **DE_analsis_sncrna\_results.tsv** is a main file with DE results. This file contains following columns:

    * `sequence` column with sncRNA sequence
    * `pirna` column with known piRNA annotation
    * `trna` column with known tRNA annotation
    * `snorna` column with known snoRNA annotation
    * `srna` column with other known small non-coding RNAs annotation (TO-DO: add link to documentation about reference preparation)
    * `mrna` column with known mRNA annotation
    * `lncrna` column with known lncRNA annotation
    * `genome_alignments` number of genomic alignments of a sequence
    * `MINT_plate`
    * `baseMean` is the average of the normalized count values, dividing by size factors, taken over all samples
    * `stat_lrt` (optional) is the value of the test statistic from LRT; present only if more there are more than 2 conditions in the design file
    * `pvalue_lrt` (optional) is the p-value of from LRT; present only if more there are more than 2 conditions in the design file
    * `padj_lrt` (optional) is the adjusted p-value from LRT; present only if more there are more than 2 conditions in the design file
    * `logFC_cond{X}_vs_cond{Y}` is log2 fold change from comparing condX VS condY
    * `stat_cond{X}_vs_cond{Y}` is the value of the test statistics from comparing condX VS condY
    * `pval_cond{X}_vs_cond{Y}` is the p-value of comparing condX VS condY
    * `padj_cond{X}_vs_cond{Y}` is the adjusted p-value of comparing condX VS condY


* **DE_analysis_sncrna_counts.tsv** contains raw and normalized counts for all samples. Each column in the file is a sample. Column header format is following:

    * `{sample_id}\_{raw|norm|vst}_{condX|condY}` where raw=raw counts, norm=DESeq2 normalized counts and vst=VST counts, first column is **gene** and corresponds to the first column of the table with DE analysis results, hence both tables can be easily merged
 
    If design file contains column `batch`, function `removeBatchEffect()` from limma package will be used to remove that batch effect from counts, hence the columns **norm** and **vst** will contain counts suitable for creating plots such as heatmaps

Main outputs from sncRNA DE analysis if design file NOT provided by user and only normalization was performed; these files are not generated if design file is provided:

* **normalized_tmm_counts_sncrna.tsv** contains edgeR TMM normalized counts
* **normalized_deseq2_counts_sncrna.tsv** contains DESeq2 normalized counts
* **normalized_vst_counts_sncrna.tsv** contains VST counts

Additional outputs from miRNA/isomiRs DE analysis:

* **analysis_data_cleaned.rds** is and R data object that contains counts table for sncRNA used for DE analysis as well as design file, saved for reproducibility purposes