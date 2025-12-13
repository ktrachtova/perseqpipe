process QUANTIFICATION_SNCRNA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/htseq_pandas:52439a4c7dbfb1f0'

    input:
    path gtf
    path mirna_overlap
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path ("*.short_rna_counts.tsv"),  emit: srna_counts_tsv
    path mirna_overlap, emit: mirna_overlap

    script:
    def prefix = bam.baseName.replaceAll(/\.Aligned\..*/, "")
    // Include --reads_threshold only if defined
    def reads_arg = params.reads_threshold != null ? "--reads_threshold ${params.reads_threshold}" : ""
    // Include --overlap_bp only if defined
    def bp_arg = params.sncrna_overlap != null ? "--overlap_bp ${params.sncrna_overlap}" : ""
    // Include --overlap_frac only if defined
    def frac_arg = params.sncrna_overlap_frac != null ? "--overlap_frac ${params.sncrna_overlap_frac}" : ""

    """
    03e_quantification_short_rna.py ${bam} ${gtf} \
        --sample_name ${prefix} \
        ${reads_arg} \
        ${bp_arg} \
        ${frac_arg}
    """
}