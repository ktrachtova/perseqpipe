process DESEQ2_MIRNA_ANALYSIS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/bioconductor-deseq2_bioconductor-edger_r-dplyr_r-readr:2c0e542d01296b58'
    
    input:
    path mirna_counts_table
    path isomirs_counts_table
    path design_file

    output:
    path "DE_analysis_mirna_*", emit: deseq2_mirna_tsv, optional: true
    path "DE_analysis_isomirs_*", emit: deseq2_isomirs_tsv, optional: true
    path "normalized_deseq2_counts_isomirs.tsv", emit: deseq2_normalized_counts_isomirs, optional: true
    path "normalized_deseq2_counts_mirna.tsv", emit: deseq2_normalized_counts_mirna, optional: true
    path "normalized_tmm_counts_isomirs.tsv", emit: deseq2_normalized_tmm_isomirs, optional: true
    path "normalized_tmm_counts_mirna.tsv", emit: deseq2_normalized_tmm_mirna, optional: true
    path "normalized_vst_counts_isomirs.tsv", emit: deseq2_normalized_vst_isomits, optional: true
    path "normalized_vst_counts_mirna.tsv", emit: deseq2_normalized_vst_mirna, optional: true
    path "analysis_data_cleaned.rds", emit: deseq2_analysis_data_rds

    script:

    """
    echo "Running DESeq2 miRNA/isomiR analysis."
    04_de_analysis_mirna.R \\
        --counts_mirna ${mirna_counts_table} \\
        --counts_isomirs ${isomirs_counts_table} \\
        ${design_file ? "--design_file ${design_file}" : ""} \\
        ${params.mirna_expression_threshold ? "--mirna_expression_threshold ${params.mirna_expression_threshold}" : ""} \\
        ${params.isomirs_expression_threshold ? "--isomirs_expression_threshold ${params.isomirs_expression_threshold}" : ""}
    """
}