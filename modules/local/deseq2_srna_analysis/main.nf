process DESEQ2_SRNA_ANALYSIS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/bioconductor-deseq2_bioconductor-edger_r-dplyr_r-readr:2c0e542d01296b58'
    
    input:
    path sncrna_counts
    path design_file

    output:
    path "DE_analysis_sncrna_*", emit: deseq2_sncrna_tsv, optional: true
    path "normalized_deseq2_counts_sncrna.tsv", emit: deseq2_normalized_counts_sncrna, optional: true
    path "normalized_tmm_counts_sncrna.tsv", emit: deseq2_normalized_tmm_sncrna, optional: true
    path "normalized_vst_counts_sncrna.tsv", emit: deseq2_normalized_vst_sncrna, optional: true
    path "analysis_data_cleaned.rds", emit: deseq2_analysis_data_rds

    script:

    """
    echo "Running DESeq2 sncRNA analysis!"
    04_de_analysis_sncrna.R \\
        --input_dir ./ \\
        ${design_file ? "--design_file ${design_file}" : ""} \\
        ${params.sncrna_expression_threshold ? "--sncrna_expression_threshold ${params.sncrna_expression_threshold}" : ""}
    """
}