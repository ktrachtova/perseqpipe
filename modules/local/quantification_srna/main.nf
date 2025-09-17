process QUANTIFICATION_SRNA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/htseq_pandas:52439a4c7dbfb1f0'

    input:
    path gtf
    tuple val(meta), path(bam), path(bai)
    //tuple val(meta), path(bam)
    //tuple val(meta), path(bai)

    output:
    tuple val(meta), path ("*.short_rna_counts.tsv"),  emit: srna_counts_tsv

    script:
    def prefix = bam.baseName.replaceAll(/\.Aligned\..*/, "")
    """
    03e_quantification_short_rna.py ${bam} ${gtf} --sample_name ${prefix}
    """
}